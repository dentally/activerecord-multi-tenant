require 'spec_helper'

describe "Query monitor" do
  before do
    MultiTenant.enable_query_monitor
  end

  context "Unscoped tenanted query" do
    let!(:account) { Account.create!(name: "Test Account") }
    let!(:project) { Project.create(name: "Project 1", account: account) }

    before do
      MultiTenant.current_tenant = nil
    end

    it "warns when tenant missing" do
      expect(ActiveRecord::Base.logger).to receive(:warn).twice.with(/WARNING: Tenant not present - make sure to add MultiTenant/)
      Project.pluck(:name)
    end
  end

  context "Explicit unscoped tenanted query using .without" do
    let!(:account) { Account.create!(name: "Test Account") }
    let!(:project) { Project.create(name: "Project 1", account: account) }

    before do
      MultiTenant.current_tenant = nil
    end

    it "does not warn when tenant missing" do
      expect(ActiveRecord::Base.logger).to_not receive(:warn).with(/WARNING: Tenant not present - make sure to add MultiTenant/)
      MultiTenant.without do
        Project.pluck(:name)
      end
    end

    context "scoped tenanted query using" do
      let!(:account) { Account.create!(name: "Test Account") }
      let!(:project) { Project.create(name: "Project 1", account: account) }

      before do
        MultiTenant.current_tenant = account
      end

      it "does not warn when tenant missing" do
        expect(ActiveRecord::Base.logger).to_not receive(:warn).with(/WARNING: Tenant not present - make sure to add MultiTenant/)
        Project.pluck(:name)
      end
    end
  end
end
