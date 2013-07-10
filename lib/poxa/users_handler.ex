defmodule Poxa.UsersHandler do
  @moduledoc """
  This module contains Cowboy HTTP handler callbacks to request on /apps/:app_id/channels/:channel/users

  More info on Pusher REST API at: http://pusher.com/docs/rest_api
  """

  require Lager
  alias Poxa.AuthorizationHelper
  alias Poxa.PresenceSubscription

  def init(_transport, req, _opts) do
    {:upgrade, :protocol, :cowboy_rest}
  end

  def allowed_methods(req, state) do
    {["GET"], req, state}
  end

  def malformed_request(req, state) do
    {channel, req} = :cowboy_req.binding(:channel_name, req)
    {!PresenceSubscription.presence_channel?(channel), req, channel}
  end

  def is_authorized(req, channel) do
    AuthorizationHelper.is_authorized(req, channel)
  end

  def content_types_provided(req, state) do
    {[{{"application", "json", []}, :get_json}], req, state}
  end

  def get_json(req, channel) do
    response = PresenceSubscription.users(channel)
      |> Enum.map(fn(id) -> [{"id", id}] end)
    {JSEX.encode!(users: response), req, response}
  end

  def terminate(_reason, _req, _state), do: :ok
end
