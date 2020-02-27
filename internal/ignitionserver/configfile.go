package ignitionserver

import (
	"context"
	"github.com/ignition-server/models"
	"github.com/ignition-server/restapi/operations/ignition_server"

	"github.com/go-openapi/runtime/middleware"

)


type configFile struct {
}

func NewConfigFile() *configFile {
	return &configFile{}
}

func (b *configFile) GetConfig(ctx context.Context, params ignition_server.GetConfigParams) middleware.Responder {
	return ignition_server.NewGetConfigOK().WithPayload(&models.ConfigParams{
			Name: "Test",
			URL: "http://aaaa.com",
			ClusterID: params.ClusterID,
			Role: params.Role,
		})
}
