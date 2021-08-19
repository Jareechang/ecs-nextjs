### Next.js on ECS  

This a demo app running on AWS ECS with full CI/CD via github actions deployed to AWS ECR.

- [Architecture](#architecture) - todo
- [Getting Started](#getting-started)
- [Reference](#reference)
- [Technologies](#technologies)

### Architecture

TODO

### Getting Started

**Running locally:**
```sh
yarn && yarn run dev

Visit http://localhost:3000  
```

**Running locally (docker):**
```sh
docker build -t ecs-nextjs .

docker run -d -p 3000:300 ecs-nextjs:latest
```

### Reference

repo is built on [example-nextjs-emotion11-material-u](https://github.com/Jareechang/example-nextjs-emotion11-material-ui) and [tf-modules](https://github.com/Jareechang/tf-modules).

[Basic Final Next.js](https://github.com/vercel/next-learn-starter/tree/master/basics-final)

### Technologies

- [emotion](https://emotion.sh/docs/@emotion/css) @ 11.0
- [material-ui](https://material-ui.com/) @ 4.11
- [next](https://nextjs.org/docs/getting-started) @ 10.x
- [polished](https://polished.js.org/docs/) @ 4.x
