# Sneaky

## Initialize

 `docker-compose run web bash` and then run:
 ```bash
mix deps.get
mix ecto.create
mix ecto.migrate
cd assets
npm install
 ```
 
 Then, after starting atleast minio, go to `localhost:9000` and create a bucket called _sneakies_.
 Make it public by adding a read-only policy to everything in that bucket.

## To run
  * `docker-compose up`
