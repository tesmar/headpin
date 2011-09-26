ComplianceManager::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.
  get "notices/get_new"

  resources :systems do
    get 'auto_complete_search' , :on => :collection
    delete :delete
    member do
      get :facts
      get :subscriptions
      post :subscriptions
      post :create
      delete :delete
      delete :subscriptions
      get :available_subscriptions
      post :update_subscriptions
      get :events
      get :manifest_dl
      post :bind
      get :bind
    end
  end

  resources :activation_keys do
    get 'auto_complete_search' , :on => :collection
  end

  match 'systems/:id/unbind/:entitlement_id', :to => 'systems#unbind'
  #match 'systems/create', :to => 'systems#create'

  namespace "admin" do
    resources :organizations do
      get 'auto_complete_search' , :on => :collection
      member do
        get :subscriptions
        post :subscriptions
        get :systems
        get :events
      end
    end
    resources :users do
      get 'auto_complete_search' , :on => :collection
      member do
        put :update_roles
        get :edit_roles
      end
    end

    match 'users/:id/roles', :to => 'users#edit_roles'
    resources :roles do
      put "create_permission" => "roles#create_permission"
      resources :permission, :only => {} do
        delete "destroy_permission" => "roles#destroy_permission", :as => "destroy"
        post "update_permission" => "roles#update_permission", :as => "update"
      end
      collection do
        get :auto_complete_search
      end
    end
  end #end admin namespace

  resource :account
  resources :login, :dashboard, :subscriptions, :imports

  match 'logout', :to => 'login#destroy'

  # Temp route for "using" a particular org:
  match 'set_org', :to => 'application#set_org'
  match 'allowed_orgs', :to => 'application#allowed_orgs'

  match 'admin', :to => 'admin/organizations#index'

  resources :search, :only => {} do
    get 'show', :on => :collection

    get 'history', :on => :collection
    delete 'history' => 'search#destroy_history', :on => :collection

    get 'favorite', :on => :collection
    post 'favorite' => 'search#create_favorite', :on => :collection
    delete 'favorite/:id' => 'search#destroy_favorite', :on => :collection, :as => 'destroy_favorite'
  end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "login#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
