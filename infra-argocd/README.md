# NEED TO GET RID OF REDIS IN ArgoCD and use common redis
redis.enabled: Set to false to disable the built-in Redis.
externalRedis.host: Set to your existing Redis endpoint.
externalRedis.port: Set to your Redis port (default is 6379).
externalRedis.password: Provide the password if authentication is