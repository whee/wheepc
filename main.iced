redis = require('redis')
client = redis.createClient()

# Request (channel name, data, callback)
# Structure:
#   - reply channel (channel name + sequence number via INCR)
#   - data
# add {id, data} structure, lpush, wait for response

exports.request = (channel, args, cb) ->
  # Nab an id for the queues and request
  await client.incr "rpc:id:#{channel}", defer err, id
  if err
    cb err

  # Request data will go here,
  reqId = "rpc:req:#{channel}:#{id}"
  # and the response hash reference goes here
  responseQ = "rpc:respq:#{channel}:#{id}"

  # Send the request
  multi = client.multi()
  multi.hmset reqId, 'rc', responseQ, 'args', args
  multi.rpush "rpc:reqq:#{channel}", reqId
  multi.exec (err, replies) ->
    if err
      cb err

    waitClient = redis.createClient()
    # Wait for the reply
    waitClient.blpop responseQ, 0, (err, resp) ->
      waitClient.quit()
      [respQ, respData] = resp
      cb err, respData

exports.handle = (channel, cb) ->
  while true
    await client.blpop "rpc:reqq:#{channel}", 0, defer err, popped
    if err
      cb err

    [reqQ, reqId] = popped
    await client.hgetall reqId, defer err, req
    if err
      cb err

    respChannel =
      rc: req.rc
      id: reqId
    cb err, respChannel, req.args

exports.respond = (channel, data, cb) ->
  multi = client.multi()
  multi.rpush channel.rc, data
  multi.del channel.id
  multi.exec (err, replies) ->
    cb err, replies

exports.quit = ->
  client.quit()
