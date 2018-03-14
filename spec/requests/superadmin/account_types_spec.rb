# encoding: utf-8

require_relative '../../acceptance_helper'

describe Superadmin::AccountTypesController do
  describe '#create' do
    before(:each) do
      @account_type = FactoryGirl.create(:account_type_pro)
      @account_type_param = {
        account_type: "PERSONAL30",
        rate_limit: @account_type.rate_limit.api_attributes
      }
    end

    after(:each) do
      @account_type.destroy
      Carto::AccountType.where(account_type: "PERSONAL30").each(&:destroy)
    end

    it 'should create account_type' do
      expect {
        post superadmin_account_types_url, { account_type: @account_type_param }.to_json, superadmin_headers

        response.status.should == 204
      }.to change(Carto::AccountType, :count).by(1)
    end

    it 'should raise an exception if account_type already exists' do
      @account_type_param[:account_type] = @account_type.account_type

      post superadmin_account_types_url, { account_type: @account_type_param }.to_json, superadmin_headers

      response.status.should == 500
      JSON.parse(response.body)['errors']['message'].should =~ /duplicate key/
    end
  end

  describe '#update' do
    before(:each) do
      Carto::AccountType.where(account_type: "PRO").each(&:destroy)
      @account_type = FactoryGirl.create(:account_type_pro)
      @rate_limits = FactoryGirl.create(:rate_limits_custom)
      @account_type_param = {
        account_type: @account_type.account_type,
        rate_limit: @rate_limits.api_attributes
      }
    end

    after(:each) do
      @rate_limits.destroy
      @account_type.destroy
    end

    it 'should update an account type' do
      ::Resque.expects(:enqueue)
              .once
              .with(Resque::UserJobs::RateLimitsJobs::SyncRedis, @account_type.account_type)
      expect {
        put superadmin_account_type_url(@account_type.account_type),
            { account_type: @account_type_param }.to_json,
            superadmin_headers

        @account_type.reload
        @account_type.rate_limit.api_attributes.should eq @rate_limits.api_attributes
      }.to change(Carto::RateLimit, :count).by(0)
    end

    it 'should not update an account type with empty rate limits' do
      ::Resque.expects(:enqueue).never

      api_attributes = @account_type.rate_limit.api_attributes
      put_json superadmin_account_type_url(@account_type.account_type),
               { account_type: { account_type: @account_type.account_type } }.to_json,
               superadmin_headers do |response|

        response.status.should == 500
        response.body[:error].should =~ /ERROR. rate_limit object is not valid/
        @account_type.rate_limit.api_attributes.should eq api_attributes
      end
    end

    it 'should raise an error if non-existent account type' do
      ::Resque.expects(:enqueue).never

      put_json superadmin_account_type_url("non_existent"),
               { account_type: { account_type: @account_type.account_type } }.to_json,
               superadmin_headers do |response|

        response.status.should == 404
        response.body[:error].should =~ /ERROR. account_type not found/
      end
    end
  end

  describe '#destroy' do
    before(:each) do
      Carto::AccountType.where(account_type: "PRO").each(&:destroy)
      @account_type = FactoryGirl.create(:account_type_pro)
    end

    after(:each) do
      @account_type.destroy
    end

    it 'should destroy account type' do
      expect {
        delete superadmin_account_type_url(@account_type.account_type), nil, superadmin_headers
      }.to change(Carto::AccountType, :count).by(-1)

      expect {
        Carto::AccountType.find(@account_type.id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'should raise an error if non-existent account type' do
      delete_json superadmin_account_type_url("non_existent"), nil, superadmin_headers do |response|

        response.status.should == 404
        response.body[:error].should =~ /ERROR. account_type not found/
      end
    end
  end
end
