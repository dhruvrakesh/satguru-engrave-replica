import { useState } from "react"
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query"
import { supabase } from "@/integrations/supabase/client"
import { useOrganization } from "@/contexts/OrganizationContext"
import { useOrganizationData } from "@/hooks/useOrganizationData"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Checkbox } from "@/components/ui/checkbox"
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs"
import { Plus, Search, Edit, Trash2, Upload } from "lucide-react"
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Textarea } from "@/components/ui/textarea"
import { useToast } from "@/hooks/use-toast"
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table"
import { ItemMasterCSVUpload } from "@/components/csv/ItemMasterCSVUpload"
import { ItemMasterBulkActions } from "@/components/csv/ItemMasterBulkActions"
import { ItemMasterRow } from "@/components/ItemMasterInlineEditor"

const ItemMaster = () => {
  const [searchTerm, setSearchTerm] = useState("")
  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [editingItem, setEditingItem] = useState(null)
  const [selectedItems, setSelectedItems] = useState<any[]>([])
  const [activeTab, setActiveTab] = useState("manage")
  const { toast } = useToast()
  const queryClient = useQueryClient()
  
  // Organization context
  const { organization, isLoading: orgLoading, isSatguru } = useOrganization()
  const { getCategories, getItems, insertItem, deleteItem, insertStock } = useOrganizationData()

  console.log('🏢 ItemMaster rendering - Org:', organization?.name, 'isSatguru:', isSatguru, 'orgLoading:', orgLoading)

  // Show organization loading state
  if (orgLoading) {
    return (
      <div className="p-6 flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
          <p>Loading organization data...</p>
        </div>
      </div>
    )
  }

  // Show if organization not found
  if (!organization) {
    return (
      <div className="p-6 flex items-center justify-center">
        <div className="text-center">
          <p className="text-destructive">Organization not found</p>
        </div>
      </div>
    )
  }

  const { data: categories } = useQuery({
    queryKey: ['categories', organization.code],
    enabled: !!organization,
    queryFn: async () => {
      console.log('🗂️ Fetching categories for org:', organization.name, 'isSatguru:', isSatguru)
      return await getCategories()
    }
  })

  const { data: items, isLoading } = useQuery({
    queryKey: ['item-master', organization.code, searchTerm, isSatguru],
    enabled: !!organization,
    queryFn: async () => {
      console.log('📦 Fetching items for org:', organization.name, 'isSatguru:', isSatguru, 'searchTerm:', searchTerm)
      
      let data = await getItems()
      
       // Apply search filter with proper type handling
      if (searchTerm && Array.isArray(data)) {
        const searchLower = searchTerm.toLowerCase()
        data = (data as any[]).filter((item: any) => 
          item?.item_name?.toLowerCase().includes(searchLower) ||
          item?.item_code?.toLowerCase().includes(searchLower)
        )
      }
      
      console.log('📦 Fetched', Array.isArray(data) ? data.length : 0, 'items for', organization.name)
      return Array.isArray(data) ? data : []
    }
  })

  const createItemMutation = useMutation({
    mutationFn: async (itemData: any) => {
      console.log('➕ Creating item for org:', organization.name, 'isSatguru:', isSatguru)
      
      // For now, let's just use a simple item code until we fix the RPC
      const category = Array.isArray(categories) ? categories.find((c: any) => c.id === itemData.category_id) : null
      const timestamp = Date.now().toString().slice(-6)
      const categoryPrefix = (category as any)?.category_name?.substring(0, 3).toUpperCase() || 'GEN'
      const simpleCode = `${categoryPrefix}-${timestamp}`

      const finalItemData = {
        ...itemData,
        item_code: simpleCode
      }

      // Use organization-aware insert
      const data = await insertItem(finalItemData) as any[]

      // Initialize stock entry using organization-aware method
      if (data && Array.isArray(data) && data.length > 0 && data[0]?.item_code) {
        try {
          await insertStock({
            item_code: data[0].item_code,
            opening_qty: 0,
            current_qty: 0
          })
        } catch (stockError) {
          console.warn('Failed to initialize stock entry:', stockError)
        }
      }

      return data
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['item-master', organization.code] })
      queryClient.invalidateQueries({ queryKey: ['categories', organization.code] })
      setIsDialogOpen(false)
      setEditingItem(null)
      toast({
        title: "Success",
        description: "Item created successfully",
      })
    },
    onError: (error) => {
      toast({
        title: "Error",
        description: error.message,
        variant: "destructive",
      })
    }
  })

  const deleteItemMutation = useMutation({
    mutationFn: async (itemId: string) => {
      console.log('🗑️ Deleting item for org:', organization.name, 'isSatguru:', isSatguru)
      await deleteItem(itemId)
    },
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['item-master', organization.code] })
      toast({
        title: "Success",
        description: "Item deleted successfully",
      })
    },
    onError: (error) => {
      toast({
        title: "Error",
        description: error.message,
        variant: "destructive",
      })
    }
  })

  const handleSubmit = (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault()
    const formData = new FormData(e.target as HTMLFormElement)
    const itemData = {
      item_name: formData.get('item_name') as string,
      category_id: formData.get('category_id') as string,
      qualifier: formData.get('qualifier') as string,
      gsm: formData.get('gsm') ? parseFloat(formData.get('gsm') as string) : null,
      size_mm: formData.get('size_mm') as string,
      uom: formData.get('uom') as string,
      usage_type: formData.get('usage_type') as string,
      status: (formData.get('status') as string) || 'active'
    }

    createItemMutation.mutate(itemData)
  }

  const handleUploadComplete = () => {
    queryClient.invalidateQueries({ queryKey: ['item-master', organization.code] });
    queryClient.invalidateQueries({ queryKey: ['categories', organization.code] });
    setActiveTab("manage");
  };

  const toggleItemSelection = (item: any) => {
    setSelectedItems(prev => {
      const isSelected = prev.find(selected => selected.id === item.id);
      if (isSelected) {
        return prev.filter(selected => selected.id !== item.id);
      } else {
        return [...prev, item];
      }
    });
  };

  const isItemSelected = (item: any) => {
    return selectedItems.find(selected => selected.id === item.id) !== undefined;
  };

  const handleDeleteItem = (item: any) => {
    if (window.confirm(`Are you sure you want to delete "${item.item_name}"?`)) {
      deleteItemMutation.mutate(item.id);
    }
  };

  const handleItemUpdate = () => {
    queryClient.invalidateQueries({ queryKey: ['item-master', organization.code] });
    queryClient.invalidateQueries({ queryKey: ['categories', organization.code] });
  };

  return (
    <div className="p-6 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold">Item Master - {organization.name}</h1>
          <p className="text-muted-foreground">Manage your inventory items and bulk operations</p>
          <div className="mt-2">
            <Badge variant={isSatguru ? "default" : "secondary"}>
              {organization.code}
            </Badge>
          </div>
        </div>
        
        <div className="flex gap-2">
          <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
            <DialogTrigger asChild>
              <Button>
                <Plus className="mr-2 h-4 w-4" />
                Add Item
              </Button>
            </DialogTrigger>
          <DialogContent className="sm:max-w-md">
            <form onSubmit={handleSubmit}>
              <DialogHeader>
                <DialogTitle>Add New Item</DialogTitle>
                <DialogDescription>
                  Enter item details. Item code will be auto-generated.
                </DialogDescription>
              </DialogHeader>
              
              <div className="space-y-4 py-4">
                <div className="space-y-2">
                  <Label htmlFor="item_name">Item Name *</Label>
                  <Input
                    id="item_name"
                    name="item_name"
                    placeholder="Enter item name"
                    required
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="category_id">Category *</Label>
                  <Select name="category_id" required>
                    <SelectTrigger>
                      <SelectValue placeholder="Select category" />
                    </SelectTrigger>
                    <SelectContent>
                      {categories?.map((category) => (
                        <SelectItem key={category.id} value={category.id}>
                          {category.category_name}
                        </SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="qualifier">Qualifier</Label>
                    <Input
                      id="qualifier"
                      name="qualifier"
                      placeholder="e.g., A, B, PREMIUM"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="gsm">GSM</Label>
                    <Input
                      id="gsm"
                      name="gsm"
                      type="number"
                      placeholder="e.g., 80"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <div className="space-y-2">
                    <Label htmlFor="size_mm">Size (mm)</Label>
                    <Input
                      id="size_mm"
                      name="size_mm"
                      placeholder="e.g., 100x200"
                    />
                  </div>
                  <div className="space-y-2">
                    <Label htmlFor="uom">UOM</Label>
                    <Select name="uom" defaultValue="PCS">
                      <SelectTrigger>
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="PCS">PCS</SelectItem>
                        <SelectItem value="KG">KG</SelectItem>
                        <SelectItem value="MTR">MTR</SelectItem>
                        <SelectItem value="SQM">SQM</SelectItem>
                        <SelectItem value="LTR">LTR</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="usage_type">Usage Type</Label>
                  <Input
                    id="usage_type"
                    name="usage_type"
                    placeholder="e.g., Production, Maintenance"
                  />
                </div>
              </div>

              <DialogFooter>
                <Button type="submit" disabled={createItemMutation.isPending}>
                  {createItemMutation.isPending ? "Creating..." : "Create Item"}
                </Button>
              </DialogFooter>
            </form>
          </DialogContent>
        </Dialog>
        </div>
      </div>

      <Tabs value={activeTab} onValueChange={setActiveTab} className="w-full">
        <TabsList>
          <TabsTrigger value="manage">Manage Items</TabsTrigger>
          <TabsTrigger value="upload">CSV Upload</TabsTrigger>
          <TabsTrigger value="bulk">Bulk Actions</TabsTrigger>
        </TabsList>

        <TabsContent value="manage" className="space-y-6">
          {/* Search */}
          <div className="relative max-w-md">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
            <Input
              placeholder="Search items..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="pl-10"
            />
          </div>

          {/* Items Table */}
          <Card>
            <CardHeader>
              <CardTitle>Items ({items?.length || 0})</CardTitle>
              <CardDescription>Manage your inventory items and view stock levels</CardDescription>
            </CardHeader>
            <CardContent>
              <div className="overflow-x-auto">
                <table className="w-full border-collapse">
                  <thead>
                    <tr className="border-b">
                      <th className="text-left p-2 w-12">
                        <Checkbox
                          checked={selectedItems.length === items?.length && items.length > 0}
                          onCheckedChange={(checked) => {
                            if (checked) {
                              setSelectedItems(items || []);
                            } else {
                              setSelectedItems([]);
                            }
                          }}
                        />
                      </th>
                      <th className="text-left p-2">Item Code</th>
                      <th className="text-left p-2">Item Name</th>
                      <th className="text-left p-2">Category</th>
                      <th className="text-left p-2">Current Stock</th>
                      <th className="text-left p-2">UOM</th>
                      <th className="text-left p-2">Status</th>
                      <th className="text-left p-2">Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {isLoading ? (
                      <tr>
                        <td colSpan={8} className="text-center p-4">Loading...</td>
                      </tr>
                    ) : items?.length === 0 ? (
                      <tr>
                        <td colSpan={8} className="text-center p-4">No items found</td>
                      </tr>
                    ) : (
                      items?.map((item) => (
                        <ItemMasterRow
                          key={item.id}
                          item={item}
                          categories={categories || []}
                          isSelected={isItemSelected(item)}
                          onSelectionChange={toggleItemSelection}
                          onUpdate={handleItemUpdate}
                          onDelete={handleDeleteItem}
                        />
                      ))
                    )}
                  </tbody>
                </table>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="upload">
          <ItemMasterCSVUpload 
            categories={categories || []} 
            onUploadComplete={handleUploadComplete}
          />
        </TabsContent>

        <TabsContent value="bulk">
          <ItemMasterBulkActions
            selectedItems={selectedItems}
            onSelectionChange={setSelectedItems}
            allItems={items || []}
            categories={categories || []}
          />
        </TabsContent>
      </Tabs>
    </div>
  )
}

export default ItemMaster