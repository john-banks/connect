chai      = require 'chai'
sinon     = require 'sinon'
sinonChai = require 'sinon-chai'
expect    = chai.expect




chai.use sinonChai
chai.should()




server          = require '../../server'
IDToken         = require '../../models/IDToken'
verifyClientReg = require('../../lib/oidc').verifyClientRegistration
  settings:
    client_registration:        'scoped'
    registration_scope:         'realm developer'
    trusted_registration_scope: 'realm'




describe 'Verify Scoped Client Registration', ->


  {req,res,next,err} = {}


  describe 'with missing bearer token', ->

    before (done) ->
      req = { headers: {}, body: {} }
      res = {}

      verifyClientReg req, res, (error) ->
        err = error
        done()

    it 'should provide an UnauthorizedError', ->
      err.name.should.equal 'UnauthorizedError'

    it 'should provide a realm', ->
      err.realm.should.equal 'user'

    it 'should NOT provide an error code', ->
      expect(err.error).to.be.undefined

    it 'should NOT provide an error description', ->
      expect(err.error_description).to.be.undefined

    it 'should provide a status code', ->
      err.statusCode.should.equal 400




  describe 'with invalid JWT bearer token', ->

    before (done) ->
      req =
        headers:
          authorization: 'Bearer invalid'
        body: {}

      res = {}

      verifyClientReg req, res, (error) ->
        err = error
        done()

    it 'should provide an UnauthorizedError', ->
      err.name.should.equal 'UnauthorizedError'

    it 'should provide a realm', ->
      err.realm.should.equal 'user'

    it 'should provide an error code', ->
      err.error.should.equal 'invalid_token'

    it 'should provide an error description', ->
      err.error_description.should.equal 'Invalid access token'

    it 'should provide a status code', ->
      err.statusCode.should.equal 401




  describe 'with insufficient trusted scope', ->

    before (done) ->
      token =
        payload:
          scope: 'insufficient'

      sinon.stub(IDToken, 'decode').returns token
      req =
        headers:
          authorization: 'Bearer valid'
        body: { trusted: "true" }

      res = {}

      verifyClientReg req, res, (error) ->
        err = error
        done()

    after ->
      IDToken.decode.restore()

    it 'should provide an UnauthorizedError', ->
      err.name.should.equal 'UnauthorizedError'

    it 'should provide a realm', ->
      err.realm.should.equal 'user'

    it 'should provide an error code', ->
      err.error.should.equal 'insufficient_scope'

    it 'should provide an error description', ->
      err.error_description.should.equal 'User does not have permission'

    it 'should provide a status code', ->
      err.statusCode.should.equal 403




  describe 'with insufficient scope', ->

    before (done) ->
      token =
        payload:
          scope: 'insufficient'

      sinon.stub(IDToken, 'decode').returns token
      req =
        headers:
          authorization: 'Bearer valid'
        body: { trusted: "false" }


      res = {}

      verifyClientReg req, res, (error) ->
        err = error
        done()

    after ->
      IDToken.decode.restore()

    it 'should provide an UnauthorizedError', ->
      err.name.should.equal 'UnauthorizedError'

    it 'should provide a realm', ->
      err.realm.should.equal 'user'

    it 'should provide an error code', ->
      err.error.should.equal 'insufficient_scope'

    it 'should provide an error description', ->
      err.error_description.should.equal 'User does not have permission'

    it 'should provide a status code', ->
      err.statusCode.should.equal 403




  describe 'with sufficient trusted scope', ->

    before (done) ->
      token =
        payload:
          scope: 'realm other'

      sinon.stub(IDToken, 'decode').returns token
      req =
        headers:
          authorization: 'Bearer valid'
        body: { trusted: "true" }

      res = {}
      next = sinon.spy (error) ->
        err = error
        done()

      verifyClientReg req, res, next

    after ->
      IDToken.decode.restore()

    it 'should not provide an error', ->
      expect(err).to.be.undefined

    it 'should continue', ->
      next.should.have.been.called




  describe 'with sufficient scope', ->

    before (done) ->
      token =
        payload:
          scope: 'developer other'

      sinon.stub(IDToken, 'decode').returns token
      req =
        headers:
          authorization: 'Bearer valid'
        body: {}

      res = {}
      next = sinon.spy (error) ->
        err = error
        done()

      verifyClientReg req, res, next

    after ->
      IDToken.decode.restore()

    it 'should not provide an error', ->
      expect(err).to.be.undefined

    it 'should continue', ->
      next.should.have.been.called



