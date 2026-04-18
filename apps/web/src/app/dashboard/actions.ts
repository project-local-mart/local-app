'use server'

import { revalidatePath } from 'next/cache'
import { redirect } from 'next/navigation'
import { apiAuth } from '@/lib/api-auth'

export async function applyAsMerchant(formData: FormData) {
  await apiAuth.merchants.apply({
    communityId: formData.get('communityId') as string,
    businessName: formData.get('businessName') as string,
    ownerName: formData.get('ownerName') as string,
    email: formData.get('email') as string,
    phone: formData.get('phone') as string,
    address: formData.get('address') as string,
    city: formData.get('city') as string,
    state: (formData.get('state') as string).toUpperCase(),
    zip: formData.get('zip') as string,
    lat: parseFloat(formData.get('lat') as string) || 0,
    lng: parseFloat(formData.get('lng') as string) || 0,
  })
  revalidatePath('/dashboard')
  redirect('/dashboard?applied=1')
}

export async function createProduct(formData: FormData) {
  const merchantId = formData.get('merchantId') as string
  const body = {
    merchantId,
    name: formData.get('name') as string,
    description: (formData.get('description') as string) || null,
    price: Math.round(parseFloat(formData.get('price') as string) * 100),
    stockQuantity: parseInt(formData.get('stockQuantity') as string, 10),
    sku: (formData.get('sku') as string) || null,
    currency: 'USD' as const,
    barcode: null,
    images: [] as string[],
    categories: [] as string[],
  }
  await apiAuth.products.create(body)
  revalidatePath('/dashboard/products')
  redirect('/dashboard/products')
}

export async function updateProduct(id: string, formData: FormData) {
  const body = {
    name: formData.get('name') as string,
    description: (formData.get('description') as string) || null,
    price: Math.round(parseFloat(formData.get('price') as string) * 100),
    stockQuantity: parseInt(formData.get('stockQuantity') as string, 10),
  }
  await apiAuth.products.update(id, body)
  revalidatePath('/dashboard/products')
  redirect('/dashboard/products')
}

export async function deleteProduct(id: string) {
  await apiAuth.products.delete(id)
  revalidatePath('/dashboard/products')
}

export async function publishProduct(id: string) {
  await apiAuth.products.publish(id)
  revalidatePath('/dashboard/products')
}
