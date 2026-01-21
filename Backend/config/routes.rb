Rails.application.routes.draw do
  get "/", to: "health#show"
  get "/health", to: "health#show"

  scope "/api" do
    post "/token", to: "api/auth#token"

    get "/warehouse", to: "api/warehouse#warehouse"
    post "/warehouse/update", to: "api/warehouse#update_inventory"
    get "/daily_stats", to: "api/warehouse#daily_stats"

    get "/items", to: "api/items#index"
    post "/items", to: "api/items#create"
    get "/items/slot/:slot_number", to: "api/items#slot"
    get "/items/:id", to: "api/items#show", constraints: { id: /\d+/ }
    put "/items/:id", to: "api/items#update", constraints: { id: /\d+/ }
    delete "/items/:id", to: "api/items#destroy", constraints: { id: /\d+/ }
    get "/items/:barcode", to: "api/warehouse#item"

    get "/transactions", to: "api/transactions#index"
    get "/transactions/:id", to: "api/transactions#show", constraints: { id: /\d+/ }
    post "/transactions", to: "api/transactions#create"
    post "/transactions/:id/refund", to: "api/transactions#refund", constraints: { id: /\d+/ }

    get "/machines", to: "api/machines#index"
    get "/machines/:id", to: "api/machines#show", constraints: { id: /\d+/ }

    get "/routes", to: "api/routes#routes"
    get "/employees", to: "api/routes#employees"
    get "/employees/routes", to: "api/employees#routes_index"
    get "/employees/:id/routes", to: "api/employees#routes_for"
    post "/employees/:id/routes/assign", to: "api/employees#assign_route"
    put "/employees/:id/routes/stops", to: "api/employees#update_stops"
    get "/employees/:id", to: "api/employees#show"
  end
end
