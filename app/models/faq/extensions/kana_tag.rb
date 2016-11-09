class Faq::Extensions::KanaTag < Array
  # convert to mongoid native type
  def mongoize
    self.to_a
  end

  def to_csv
    self.map { |h| "#{h['tag']},#{h['kana']}" }.join("\n")
  end

  class << self
    # convert mongoid native type to its custom type(this class)
    def demongoize(object)
      self.new(object.to_a)
    end

    # convert any possible object to mongoid native type
    def mongoize(object)
      case object
      when self then
        object.mongoize
      when String then
        self.create_from_csv(object.to_s).mongoize
      when Array then
        self.new(object.to_a).mongoize
      when Hash then
        self.new([ object.to_h ]).mongoize
      else
        # unknown type
        object
      end
    end

    # convert the object which was supplied to a criteria, and convert it to mongoid-friendly type
    def evolve(object)
      case object
      when self then
        object.mongoize
      else
        # unknown type
        object
      end
    end

    def create_from_csv(csv)
      tags = []
      csv.split(/\n/).each do |line|
        tag, kana = line.strip.split(/[\s,]+/)
        next if tag.blank? || kana.blank?
        tags << { 'tag' => tag.strip, 'kana' => kana.strip }
      end

      self.new(tags)
    end
  end
end
