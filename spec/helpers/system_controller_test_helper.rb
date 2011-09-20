module SystemControllerTestHelper
  def post_to_headpin_create_data
    {"arch" => {"arch_id" => "i386"},
     "system_type" => {"virtualized" => 'virtual'},
     "system" => {"sockets" => "32", "name" => "TestSys"}
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

