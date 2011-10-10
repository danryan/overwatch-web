class Model
  include Ascribe::Attributes
  include ActiveSupport::Rescuable
  
  def self.find(key)
    begin
      response = RestClient.get("#{url}/#{key}")
      model = Yajl.load(response)
      new(model)
    rescue
      nil
    end
  end
  
  def self.create(attrs={})
    model = new(attrs)
    model.create
  end
  
  def create
    begin
      response = RestClient.post("#{url}", Yajl.dump(attributes))
      model_attributes = Yajl.load(response)
      update(model_attributes)
      return self
    rescue RestClient::Exception => e
      response = { :code => e.http_code.to_s, :errors => Yajl.load(e.http_body) }
      Rails.logger.info response
      response[:errors].each_pair do |key, messages|
        messages.each do |message|
          errors.add(key.to_sym, message)
        end
      end
      return self
    end
  end
  
  def update_attributes
    begin
      response = RestClient.put("#{url}/#{id}", Yajl.dump(attributes))
      model_attributes = Yajl.load(response)
      update(model_attributes)
      return self
    rescue RestClient::Exception => e
      response = { :code => e.http_code.to_s, :errors => Yajl.load(e.http_body) }
      Rails.logger.info response
      response[:errors].each_pair do |key, messages|
        messages.each do |message|
          errors.add(key.to_sym, message)
        end
      end
      return self
    end
  end
  
  def save
    # Check for an existing record
    if new_record?
      create
    else
      update_attributes
    end
  end
  
  def self.all(options={})
    response = RestClient.get("#{url}")
    collection_attributes = Yajl.load(response)
    
    collection ||= collection_attributes.inject([]) do |array, resource|
      array << new(resource)
    end
    collection
  end
  
  def new_record?
    model = self.class.find(id)
    if model.nil?
      true
    else
      false
    end
  end
      
  def destroy
    begin
      response = RestClient.delete("#{url}/#{id}")
      return self
    rescue RestClient::ResourceNotFound => e
      response = { :code => e.http_code.to_s, :errors => Yajl.load(e.http_body) }
      Rails.logger.info response
      response[:errors].each do |error|
        errors.add(:id, error)
      end
      return self
    end
  end
end