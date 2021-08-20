### Next.js on ECS  

This a demo app running on AWS ECS with full CI/CD via github actions deployed to AWS ECR.

- [Architecture](#architecture) - todo
- [Getting Started](#getting-started)
- [Reference](#reference)
- [Technologies](#technologies)

### Architecture


#### Infrastructure (AWS)

![AWS ECS architecture](./images/infrastructure/ecs-nextjs.svg)

#### CI/CD

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

docker run -d -p 3000:3000 -e PORT=3000 ecs-nextjs:latest
```

### Infrastructure setup 

**Setup AWS envronment:**
```
terraform init
terraform plan
terraform apply
```

**Setup Github actions:**

The build is defined via the github actions workflow in `.github/workflows/main.yml`

As for the deployment, In order for the deployment pipeline to work you will need the following `secrets` set on your github actions:

| Environment   |  Description |  required  |
|---|---|---|
| AWS_ACCESS_KEY_ID  | AWS access ID  |   Yes |
| AWS_SECRET_ACCESS_KEY  | AWS secret access key  |   Yes |


Once all setup trigger a deployment then visit the link on the ALB (A record).


**Finishing up:**

Remember to run `terraform destroy -auto-approve` once finished with testing.

### Reference

repo is built on [example-nextjs-emotion11-material-u](https://github.com/Jareechang/example-nextjs-emotion11-material-ui) and [tf-modules](https://github.com/Jareechang/tf-modules).

[Basic Final Next.js](https://github.com/vercel/next-learn-starter/tree/master/basics-final)

### Technologies

- [emotion](https://emotion.sh/docs/@emotion/css) @ 11.0
- [material-ui](https://material-ui.com/) @ 4.11
- [next](https://nextjs.org/docs/getting-started) @ 10.x
- [polished](https://polished.js.org/docs/) @ 4.x
- terraform
- AWS ECS 
- AWS ECR
- AWS VPC (subnets, route table, netowrk acl, igw, nat gw)
- AWS SSM
- AWS ALB
