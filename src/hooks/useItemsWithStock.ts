
import { useQuery } from "@tanstack/react-query"
import { useOrganizationData } from "@/hooks/useOrganizationData"
import { useOrganization } from "@/contexts/OrganizationContext"

export const useItemsWithStock = () => {
  const { organization, isLoading: orgLoading, isSatguru } = useOrganization()
  const { getItems, getStock } = useOrganizationData()
  
  return useQuery({
    queryKey: ['items-with-stock', organization?.code, isSatguru],
    enabled: !orgLoading && !!organization, // Wait for organization to load
    queryFn: async () => {
      console.log('🔍 useItemsWithStock executing - Org:', organization?.name, 'isSatguru:', isSatguru);
      // Get items with category info
      const items = await getItems()

      // Get stock data
      const stockData = await getStock()

      console.log('Fetched items:', items?.length || 0)
      console.log('Fetched stock data:', stockData?.length || 0)

      // Combine items with stock data (ensure stockData is an array)
      const stockArray = Array.isArray(stockData) ? stockData : []
      return (items || []).map((item: any) => {
        const stock = stockArray.find((s: any) => s?.item_code === item?.item_code)
         return {
           item_code: item?.item_code,
           item_name: item?.item_name,
           uom: item?.uom,
           category_name: item?.categories?.category_name || item?.satguru_categories?.category_name || 'Uncategorized',
           current_qty: Number((stock && typeof stock === 'object' && 'current_qty' in stock) ? stock.current_qty : 0),
           status: item?.status || 'active'
         }
      })
    }
  })
}
