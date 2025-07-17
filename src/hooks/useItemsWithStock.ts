
import { useQuery } from "@tanstack/react-query"
import { useOrganizationData } from "@/hooks/useOrganizationData"

export const useItemsWithStock = () => {
  const { getItems, getStock } = useOrganizationData()
  
  return useQuery({
    queryKey: ['items-with-stock'],
    queryFn: async () => {
      // Get items with category info
      const itemsResult = await getItems()
      const { data: items, error: itemsError } = itemsResult
      if (itemsError) {
        console.error('Error fetching items:', itemsError)
        throw itemsError
      }

      // Get stock data
      const stockResult = await getStock()
      const { data: stockData, error: stockError } = stockResult
      if (stockError) {
        console.error('Error fetching stock:', stockError)
        throw stockError
      }

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
          current_qty: (stock && typeof stock === 'object' && 'current_qty' in stock) ? stock.current_qty : 0,
          status: item?.status || 'active'
        }
      })
    }
  })
}
