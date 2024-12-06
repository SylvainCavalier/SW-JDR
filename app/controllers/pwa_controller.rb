class PwaController < ApplicationController
  skip_forgery_protection
  skip_before_action :authenticate_user!, only: [:service_worker, :manifest]

  def service_worker
    render template: "pwa/service-worker", layout: false
  end
  
  def manifest
    render template: "pwa/manifest", layout: false
  end
end