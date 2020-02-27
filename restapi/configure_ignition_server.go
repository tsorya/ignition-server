// Code generated by go-swagger; DO NOT EDIT.

package restapi

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/go-openapi/errors"
	"github.com/go-openapi/loads"
	"github.com/go-openapi/runtime"
	"github.com/go-openapi/runtime/middleware"

	"github.com/ignition-server/restapi/operations"
	"github.com/ignition-server/restapi/operations/ignition_server"
)

type contextKey string

const AuthKey contextKey = "Auth"

//go:generate mockery -name IgnitionServerAPI -inpkg

// IgnitionServerAPI
type IgnitionServerAPI interface {
	GetConfig(ctx context.Context, params ignition_server.GetConfigParams) middleware.Responder
}

// Config is configuration for Handler
type Config struct {
	IgnitionServerAPI
	Logger func(string, ...interface{})
	// InnerMiddleware is for the handler executors. These do not apply to the swagger.json document.
	// The middleware executes after routing but before authentication, binding and validation
	InnerMiddleware func(http.Handler) http.Handler

	// Authorizer is used to authorize a request after the Auth function was called using the "Auth*" functions
	// and the principal was stored in the context in the "AuthKey" context value.
	Authorizer func(*http.Request) error
}

// Handler returns an http.Handler given the handler configuration
// It mounts all the business logic implementers in the right routing.
func Handler(c Config) (http.Handler, error) {
	h, _, err := HandlerAPI(c)
	return h, err
}

// HandlerAPI returns an http.Handler given the handler configuration
// and the corresponding *IgnitionServer instance.
// It mounts all the business logic implementers in the right routing.
func HandlerAPI(c Config) (http.Handler, *operations.IgnitionServerAPI, error) {
	spec, err := loads.Analyzed(swaggerCopy(SwaggerJSON), "")
	if err != nil {
		return nil, nil, fmt.Errorf("analyze swagger: %v", err)
	}
	api := operations.NewIgnitionServerAPI(spec)
	api.ServeError = errors.ServeError
	api.Logger = c.Logger

	api.JSONConsumer = runtime.JSONConsumer()
	api.JSONProducer = runtime.JSONProducer()
	api.IgnitionServerGetConfigHandler = ignition_server.GetConfigHandlerFunc(func(params ignition_server.GetConfigParams) middleware.Responder {
		ctx := params.HTTPRequest.Context()
		return c.IgnitionServerAPI.GetConfig(ctx, params)
	})
	api.ServerShutdown = func() {}
	return api.Serve(c.InnerMiddleware), api, nil
}

// swaggerCopy copies the swagger json to prevent data races in runtime
func swaggerCopy(orig json.RawMessage) json.RawMessage {
	c := make(json.RawMessage, len(orig))
	copy(c, orig)
	return c
}

// authorizer is a helper function to implement the runtime.Authorizer interface.
type authorizer func(*http.Request) error

func (a authorizer) Authorize(req *http.Request, principal interface{}) error {
	if a == nil {
		return nil
	}
	ctx := storeAuth(req.Context(), principal)
	return a(req.WithContext(ctx))
}

func storeAuth(ctx context.Context, principal interface{}) context.Context {
	return context.WithValue(ctx, AuthKey, principal)
}