# Freshcom Web

This repo contains the web layer of the [Freshcom Project](https://github.com/freshcom/freshcom). It builds on top of [freshcom](https://github.com/freshcom/freshcom) and provides a [JSON API](https://jsonapi.org/). This repo does not contain any UI

- For a back office UI please checkout [freshcom_dashboard](https://github.com/freshcom/freshcom_dashboard).
- You will have to build your own storefront UI, we recommand [VueJS](https://vuejs.org/) but any solid SPA framework will do.

## Status of Development

Currently in early development with estimated alpha version in 6-12 months.

## Getting Started

### External Dependencies

Since freshcom_web depends on [freshcom](https://github.com/freshcom/freshcom) to do all the heavy lifting, please checkout the [external dependencies of freshcom](https://github.com/freshcom/freshcom) and make sure you have all the external dependencies.

### Setup

#### 1. Install Mix Depedencies

Since [freshcom](https://github.com/freshcom/freshcom) is not yet published as a mix package, you will need to clone it first to make it available locally.

```
$ git clone https://github.com/freshcom/freshcom
$ git clone https://github.com/freshcom/freshcom_web
$ cd freshcom_web
$ mix deps.get
```

#### 2. Generate RSA Key Pairs

freshcom_web uses RSA key pairs to sign tokens used for authentication so use the following to generate the key pairs.

```
$ mkdir keys/dev
$ cd keys/dev
$ openssl genrsa -out private.pem 2048
$ openssl rsa -in private.pem -outform PEM -pubout -out public.pem
```

You should see two files get created inside the `keys/dev` directory.

#### 3. Set Environment Variables

Once all the mix dependencies are installed we need to config the environment variables. Please copy paste `.env.example` and rename it to `.env` add in all the relevant environment variables. Then run `source .env` to set all the variables.

#### 4. Setup Database

Setup the database needed by [freshcom](https://github.com/freshcom/freshcom) with `mix freshcom.setup` which will do the following for you:

- Create the projection (read side) database and run all the relevant migrations
- Create and initialize the eventstore (write side) database

#### 5. Create a freshcom app for freshcom_dashboard (optional)

If you plan to use [freshcom_dashboard](https://github.com/freshcom/freshcom_dashboard) you will need to create a freshcom app so that freshcom_dashboard can use the app ID to identify itself with the JSON API in order to gain access all the API it needs. Simply run the following to get the app created and its app ID will be displayed.

```
$ mix freshcom.init_dashboard
```

To see where to use this app ID please view the guide for [freshcom_dashboard](https://github.com/freshcom/freshcom_dashboard).

### Run

freshcom_web is built using [phoenix](https://phoenixframework.org/) so starting the server is simply ```mix phx.server```.

Once the server is running you can try hit any of the endpoint provided to test if its working. API documentation can be found [here]()

## Learn more

  * API Documentation: http://www.comingsoon.io/
  * Guides: https://docs.freshcom.io

## Contact

Any question or feedback feel free to find me in the Elixir Slack Channel @rbao, will usually respond within few hours in PST timezone day time.
