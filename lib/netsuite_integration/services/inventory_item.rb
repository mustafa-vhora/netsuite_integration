module NetsuiteIntegration
  module Services
    # Make sure "Sell Downloadble Files" is enabled in your NetSuite account
    # otherwise search won't work
    #
    # In order to retrieve a Matrix Item you also need to enable "Matrix Items"
    # in your Company settings
    #
    # Specify Item type because +search+ maps to NetSuite ItemSearch object
    # which will bring all kinds of items and not only inventory items
    #
    # Records need to be ordered by lastModifiedDate programatically since
    # NetSuite api doesn't allow us to do that on the request. That's the
    # reason the search lets the page size default of 1000 records. We'd better
    # catch all items at once and sort by date properly or we might end up
    # losing data
    class InventoryItem < Base
      def latest
        matrix_parent_only.sort_by { |c| c.last_modified_date.utc }
      end

      def find_by_name(name)
        NetSuite::Records::InventoryItem.search({
          criteria: {
            basic: [{
              field: 'displayName',
              value: name,
              operator: 'contains'
            }]
          }
        }).results
      end

      private
        def search
          NetSuite::Records::InventoryItem.search({
            criteria: {
              basic: [
                {
                  field: 'lastModifiedDate',
                  operator: 'after',
                  value: last_updated_after
                },
                {
                  field: 'type',
                  operator: 'anyOf',
                  type: 'SearchEnumMultiSelectField',
                  value: ['_inventoryItem']
                },
                {
                  field: 'isInactive',
                  value: false
                },
                {
                  field: 'isOnline',
                  value: true
                }
              ]
            }
          }).results
        end

        def matrix_parent_only
          search.select { |item| item.matrix_type.nil? || item.matrix_type == "_parent" }
        end

        def last_updated_after
          date = Time.parse config.fetch('netsuite.last_updated_after')
          date.iso8601
        end
    end
  end
end
