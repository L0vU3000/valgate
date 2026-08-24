import type { Property } from "@/lib/data/types/property";
import type { Document } from "@/lib/data/types/document";
import type { Ctx } from "@/lib/services/_mapping";

// Intentionally small public DTOs for HTTP API v1. Every field here is deliberate — never
// spread a full Property/Ctx-derived object. Omitted on purpose: userId, orgId, clientId,
// every storage id (photoStorageIds/documentStorageIds/coverStorageId), every evidence-doc
// id array, and all *Verified*/financial internals.
export type MeDto = {
  email: string;
  displayName: string | null;
  role: Ctx["orgRole"];
  orgName: string;
};

export type MeProfile = {
  email: string;
  displayName: string | null;
  role: Ctx["orgRole"];
  orgName: string;
};

export function toMeDto(profile: MeProfile): MeDto {
  return {
    email: profile.email,
    displayName: profile.displayName,
    role: profile.role,
    orgName: profile.orgName,
  };
}

export type PropertyListItemDtoV1 = {
  id: string;
  name: string;
  type: Property["type"];
  status: Property["status"];
  city: string | undefined;
  province: string | undefined;
  lat: number;
  lng: number;
  createdAt: number;
};

export function toPropertyListItemDto(property: Property): PropertyListItemDtoV1 {
  return {
    id: property.id,
    name: property.name,
    type: property.type,
    status: property.status,
    city: property.city,
    province: property.province,
    lat: property.lat,
    lng: property.lng,
    createdAt: property.createdAt,
  };
}

export type PropertyDetailDtoV1 = PropertyListItemDtoV1 & {
  addressLine: string | undefined;
  country: string | undefined;
  totalArea: string;
  bedrooms: string | undefined;
  bathrooms: string | undefined;
  yearBuilt: string | undefined;
};

export function toPropertyDetailDto(property: Property): PropertyDetailDtoV1 {
  return {
    ...toPropertyListItemDto(property),
    addressLine: property.addressLine,
    country: property.country,
    totalArea: property.totalArea,
    bedrooms: property.bedrooms,
    bathrooms: property.bathrooms,
    yearBuilt: property.yearBuilt,
  };
}

// Deliberately public document DTO: never include storageId/thumbStorageId or any
// AI/evidence/verification fields — those are internal-only.
export type DocumentUploadDtoV1 = {
  id: string;
  propertyId: string;
  name: string;
  kind: Document["kind"];
  mimeType: string;
  sizeBytes: number;
  uploadedAt: number;
};

export function toDocumentUploadDto(document: Document): DocumentUploadDtoV1 {
  return {
    id: document.id,
    propertyId: document.propertyId,
    name: document.name,
    kind: document.kind,
    mimeType: document.mimeType ?? "",
    sizeBytes: document.sizeBytes ?? 0,
    uploadedAt: document.uploadedAt,
  };
}
