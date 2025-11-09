package main

import (
	"gringotts-bank-backend/lambda/GetHealthcheckAPI/config"
	"gringotts-bank-backend/lambda/GetHealthcheckAPI/handler"
	"gringotts-bank-backend/lambda/GetHealthcheckAPI/processor"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/awslabs/aws-lambda-go-api-proxy/httpadapter"
)

func main() {
	// Composition root: main initializes everything
	conf := config.New()
	proc := processor.NewProcessor(&conf)
	h := handler.NewHandler(&conf, proc)

	adapter := httpadapter.New(h)
	lambda.Start(adapter.ProxyWithContext)
}
