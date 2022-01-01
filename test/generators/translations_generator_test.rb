require "test_helper"
require_relative "../rails_app/config/environment"
require "generators/rodauth/translations_generator"

class InstallGeneratorTest < Rails::Generators::TestCase
  tests Rodauth::Rails::TranslationsGenerator
  destination File.expand_path("#{__dir__}/../../tmp")
  setup :prepare_destination

  teardown do
    I18n.available_locales = [:en, :hr]
  end

  test "available locales" do
    run_generator %w[en]

    assert_file "config/locales/rodauth.en.yml" do |content|
      translations = YAML.load(content)
      assert_equal "Password", translations["en"]["rodauth"]["password_label"]
    end
  end

  test "new locales" do
    run_generator %w[pt]

    assert_file "config/locales/rodauth.pt.yml" do |content|
      translations = YAML.load(content)
      assert_equal "Palavra-passe", translations["pt"]["rodauth"]["password_label"]
    end
  end

  test "default locales" do
    run_generator %w[]

    assert_file "config/locales/rodauth.en.yml"
    assert_file "config/locales/rodauth.hr.yml"
  end

  test "used translations" do
    run_generator %w[en]

    assert_file "config/locales/rodauth.en.yml" do |content|
      translations = YAML.load(content)
      assert_equal "Password", translations["en"]["rodauth"]["password_label"]
      assert_nil translations["en"]["rodauth"]["email_auth_request_button"]
    end
  end

  test "existing translations" do
    create_file "config/locales/rodauth.en.yml", <<~YAML
      en:
        rodauth:
          login_label: Email
    YAML

    run_generator %w[en --force]

    assert_file "config/locales/rodauth.en.yml" do |content|
      translations = YAML.load(content)
      assert_equal "Email", translations["en"]["rodauth"]["login_label"]
      assert_equal "Password", translations["en"]["rodauth"]["password_label"]
    end
  end

  test "keeping custom translations" do
    create_file "config/locales/rodauth.en.yml", <<~YAML
      en:
        rodauth:
          foo: "Bar"
    YAML

    run_generator %w[en --force]

    assert_file "config/locales/rodauth.en.yml" do |content|
      translations = YAML.load(content)
      assert_equal "Bar", translations["en"]["rodauth"]["foo"]
      assert_equal "Login", translations["en"]["rodauth"]["login_label"]
    end
  end

  test "unknown locales" do
    output = run_generator %w[xy]

    assert_equal "No translations for locale: xy", output.split("\n").first
    assert_no_file "config/locales/rodauth.xy.yml"
  end

  test "no locales" do
    I18n.available_locales = nil

    output = run_generator %w[]

    assert_equal "No locales specified!", output.strip
  end

  test "no YAML header" do
    run_generator %w[en]

    assert_file "config/locales/rodauth.en.yml" do |content|
      # assert that first line is not "---"
      assert_equal "en:", content.split("\n").first
    end
  end

  test "no line wrapping" do
    run_generator %w[en]

    assert_file "config/locales/rodauth.en.yml" do |content|
      assert_match %(verify_account_resend_explanatory_text: "<p>If you no longer have the email to verify the account, you can request that it be resent to you:</p>"), content
    end

  end

  private

  def create_file(path, content)
    path = File.join(destination_root, path)
    mkdir_p File.dirname(path)
    File.write(path, content)
  end
end
