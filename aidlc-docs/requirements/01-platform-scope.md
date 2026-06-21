# Requirement: Ecommerce platform scope (v1)

## Goal
A minimal ecommerce backend that demonstrates a clean microservice split where
each service owns its own data and communicates only over HTTP.

## In scope
- Users can be created and looked up (`user-service`).
- Orders can be created and listed (`order-service`).
- An order must reference a real user — validated live against `user-service`.
- A single public entry point routes traffic (`api-gateway`).

## Out of scope (v1)
- Authentication / authorization
- Payments
- A real message broker (the `order.created` event is defined as a contract but
  emission is logged, not published to a broker yet)
- Persistent databases (services use in-memory stores for the demo)

## Non-negotiable constraints
- No cross-service code imports. HTTP only.
- No cross-service database foreign keys.
- `shared-contracts/` is the source of truth for every API and event.
