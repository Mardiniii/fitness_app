Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]

  # Practitioner side
  resource :dashboard, only: [ :show ]

  resources :programs do
    member { post :open_draft }
  end

  resources :program_versions, only: [] do
    member { patch :publish; post :fork }
    resources :program_weeks, only: [ :create ]
  end

  resources :program_weeks, only: [ :update, :destroy ] do
    member { post :duplicate }
    resources :program_days, only: [ :create ]
  end

  resources :program_days, only: [ :update, :destroy, :show ] do
    resources :program_blocks, only: [ :create ]
  end

  resources :program_blocks, only: [ :update, :destroy ] do
    member { post :duplicate; post :add_child }
    resources :block_exercises, only: [ :create ]
  end

  resources :block_exercises, only: [ :edit, :update, :destroy ] do
    member { post :move }
    resources :alternatives, only: [ :create ], controller: "block_exercise_alternatives"
  end

  resources :block_exercise_alternatives, only: [ :destroy ], path: "alternatives"

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
