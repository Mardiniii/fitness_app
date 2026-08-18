Rails.application.routes.draw do
  devise_for :users, skip: [ :registrations ]

  # Practitioner side
  resource :dashboard, only: [ :show ]

  # M4 -- check-ins and progress
  resources :check_ins, only: %i[index new create edit update destroy]
  # controller: is mandatory here. Rails pluralizes a singleton resource to
  # find its controller, and "progress".pluralize is "progresses" -- so this
  # routed to a ProgressesController that does not exist. Nothing failed
  # until somebody clicked the link.
  resource  :progress,  only: [ :show ], controller: "progress"

  # Practitioner's view of one client (P3)
  resources :clients, only: [ :show ]

  # Client side -- the gym experience
  resources :sessions, only: [ :show, :create ] do
    member { patch :complete }
    resources :set_logs, only: [ :create ]
  end

  resources :programs do
    member { post :open_draft }
    resources :program_assignments, only: [ :create ], path: "assignments"
  end

  resources :program_assignments, only: [ :update, :destroy ], path: "assignments"

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

  # The front door depends on who is knocking. Devise's `authenticated`
  # constraint keeps the signed-in experience exactly as it was -- "/" is still
  # the dashboard for a session that has a user -- while a logged-out visitor
  # gets the public landing page instead of a sign-in form.
  #
  # Both routes answer "/", so root_path still generates "/" and every existing
  # `redirect_to root_path` lands where it always did for a signed-in user.
  authenticated :user do
    root "dashboards#show", as: :authenticated_root
  end

  root "pages#home"
end
