Overwatch::Web::Application.routes.draw do
  resources :resources do
    resources :snapshots
  end
end
