# Freshcom Web

This repo contains the web layer of the [Freshcom Project](https://github.com/freshcom/freshcom). It builds on top of [freshcom](https://github.com/freshcom/freshcom) and provides a [JSON API](https://jsonapi.org/). This repo does not contain any UI, for a back office UI please checkout [freshcom_dashboard](https://github.com/freshcom/freshcom_dashboard). You will have build your own storefront UI, we recommand [VueJS](https://vuejs.org/) but solid SPA framework will do.

## Status of Development

Currently in early development with estimated beta version in 6-12 months.

## Getting Started

### External Dependencies

Since freshcom_web depends on [freshcom](https://github.com/freshcom/freshcom) to do all the heavy lifting, please checkout the [external dependencies of freshcom](https://github.com/freshcom/freshcom).

### Setup

#### Install Mix Depedencies

Since [freshcom](https://github.com/freshcom/freshcom) is not yet published as a mix package, you will need to clone it first to make it available locally.

```
$ git clone https://github.com/freshcom/freshcom
$ git clone https://github.com/freshcom/freshcom_web
$ cd freshcom_web
$ mix deps.get
```

#### Generate RSA Key Pairs

Freshcom API uses RSA key pairs to sign tokens used for authentication so use the following to generate the key pairs.

```
$ mkdir keys/dev
$ cd keys/dev
$ openssl genrsa -out private.pem 2048
$ openssl rsa -in private.pem -outform PEM -pubout -out public.pem
```

You should see two files get created inside the `keys/dev` directory.

#### Set Environment Variables

Once all the mix dependencies are installed we need to config the environment variables. Please copy paste `.env.example` and rename it to `.env`. 




To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
