# -*- coding: utf-8 -*-
module SystemControllerTestHelper
  def post_to_headpin_create_data
    {"arch" => {"arch_id" => "i386"},
     "system_type" => {"virtualized" => 'virtual'},
     "system" => {"sockets" => "32", "name" => "TestSys"}
    }
  end

  def post_to_headpin_create_data_bad_name
    {"arch" => {"arch_id" => "i386"},
     "system_type" => {"virtualized" => 'virtual'},
     "system" => {"sockets" => "32", "name" => "Name With Space"}
    }
  end

  # An abbreviated version of the POST json with one item being subscribed to
  def post_to_headpin_systems_update_subscriptions
    {"commit"=>"Subscribe", 
      "system"=>{"ff80808132ca376c0132ca3838760284"=>"false"}, 
      "spinner"=>{"ff80808132ca376c0132ca3839eb02d7"=>"0", 
        "ff80808132ca376c0132ca3838760284"=>"1", 
        "ff80808132ca376c0132ca384bd806c2"=>"0", 
        "ff80808132ca376c0132ca38443604e5"=>"0"
      }
    }
  end

  def ready_to_be_created_system
    s = System.new
    s.owner = mock(Object, :key => "admin")
    s.arch = "i386"
    s.sockets = "32"
    s.virtualized = 'virtual'
    s.name = "TestSys"
    s
  end
end

