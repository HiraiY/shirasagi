module Faq::Addon
  module Tag
    extend ActiveSupport::Concern
    extend SS::Addon

    included do
      field :kana_tags, type: Faq::Extensions::KanaTag
      permit_params :kana_tags
    end

    module ClassMethods
      def grouped_tag_list
        pipes = []
        pipes << { "$match"=> all.selector.to_h }
        pipes << { "$unwind"=>"$kana_tags" }
        pipes << { "$group" => {
          _id: { "tag" => "$kana_tags.tag", "kana" => "$kana_tags.kana" },
        } }
        pipes << { "$sort" => { "_id.kana" => 1 } }
        aggregation = Cms::Page.collection.aggregate(pipes)
        k = %w(あ か さ た な は ま や ら わ)
        aggregation = aggregation.map do |i|
          Hash[ "kana", i["_id"]["kana"], "tag", i["_id"]["tag"] ]
        end
        aggregation = aggregation.group_by do |n|
          k[k.index{ |i| i > n["kana"][0] }.to_i - 1]
        end
        aggregation
      end
    end

    def find_faq_search_node
      p = self.parent
      while p
        return p if p.try(:route) == 'faq/search'

        node = p.children.and_public.where(route: 'faq/search').first
        return node if node

        p = p.parent
      end

      Faq::Node::Search.site(self.site).and_public.first
    end
  end
end
