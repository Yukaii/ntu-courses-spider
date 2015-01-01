require 'json'

class Course
  attr_accessor :title, :code, :lecturer, :credits, 
                :required, :full_semester, :semester,
                :limitations, :time_location, :website,
                :note, :url, :take_option, :serial_number,
                :id, :target, :order, :number
  # attr_accessor :attributes

  def initialize(h)
    @attributes = [:title, :code, :lecturer, :credits, 
                   :required, :full_semester, :semester,
                   :limitations, :time_location, :website,
                   :note, :url, :take_option, :serial_number,
                   :id, :target, :order, :number]
    
    h.each {|k,v| send("#{k}=",v)}
  end
  
  def to_hash
    @data = Hash[ @attributes.map {|d| [d.to_s, self.instance_variable_get('@'+d.to_s)]} ]  
  end

end