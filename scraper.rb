#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'scraped'
require 'scraperwiki'
require 'pry'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'
# require 'scraped_page_archive/open-uri'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_url(url, gender)
  noko = noko_for(url)
  noko.css('#deuxlistes a[href*="vos-representants"]/@href').each do |link|
    scrape_person(link.text, gender)
  end
end

def scrape_person(url, gender)
  noko = noko_for(url)
  box = noko.css('div.item-page')

  data = {
    id:     url[/rep=(.*)/, 1],
    name:   box.css('div[style*="font-size:22px"]').text.sub(/\s+\([^)]+\)/, '').tidy,
    area:   box.xpath('.//text()[contains(.,"Section :")]/../span').text,
    party:  box.xpath('.//text()[contains(.,"Political group :")]/../following-sibling::div[1]').text.strip,
    email:  box.xpath('.//text()[contains(.,"Contact :")]/../following-sibling::div/a').text,
    image:  box.css('a[rel="sexylightbox"]/@href').text,
    gender: gender,
    term:   '2013',
    source: url,
  }
  data[:image] = URI.join(url, URI.escape(data[:image])).to_s unless data[:image].to_s.empty?
  ScraperWiki.save_sqlite(%i[id term], data)
end

gender_map = {
  'm' => 'male',
  'f' => 'female',
}

%w[m f].each do |sexe|
  url = "http://www.assemblee.pf/_contenu/_pages_jumi/__recherche-rep-en.php?req=SELECT%20representant.actif,%20representant.id_representant,%20representant.nom%20AS%20nom_rep,%20representant.fichier_photo,%20representant.prenom%20AS%20prenom_rep,%20groupe_politique.nom%20AS%20nom_groupe,%20section.titre%20AS%20titre_section,%20groupe_politique.code_couleur%20FROM%20%20representant,%20groupe_politique,%20section%20WHERE%20actif=1%20AND%20representant.nom!=%27VACANT%27%20AND%20groupe_politique_id=id_groupe_politique%20AND%20section_id=id_section%20AND%20sexe=%27#{sexe}%27%20ORDER%20BY%20nom_rep"
  scrape_url(url, gender_map[sexe])
end
