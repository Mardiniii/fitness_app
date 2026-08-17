Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]

  # Practitioner side
  resource :dashboard, only: [ :show ]

  resources :exercises, except: [ :show ] do
    member     { patch :confirm; patch :restore }
    collection { patch :confirm_all }
  end

  # Liveness probe for load balancers and uptime monitors
  get "up" => "rails/health#show", as: :rails_health_check

  # Installable client app: the gym-side experience runs as a PWA so set
  # logging survives bad connectivity without an app store in the loop.
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "dashboards#show"
end
