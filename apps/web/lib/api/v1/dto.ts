import type { Property } from "@/lib/data/types/property";
import type { Document } from "@/lib/data/types/document";
import type { Lease } from "@/lib/data/types/lease";
import type { PropertyValuation } from "@/lib/data/types/property-valuation";
import type { OwnershipRecord } from "@/lib/data/types/ownership-record";
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

// Deliberately public lease summary DTO: never include tenantId (internal tenant
// linkage) or any payment/expense metadata — those live on separate entities and
// are never joined into this endpoint.
export type LeaseSummaryDtoV1 = {
  id: string;
  propertyId: string;
  unit: string;
  stage: Lease["stage"];
  startDate: number;
  endDate: number;
  monthlyRent: number;
  termMonths: number;
  renewalStatus: string | undefined;
};

export function toLeaseSummaryDto(lease: Lease): LeaseSummaryDtoV1 {
  return {
    id: lease.id,
    propertyId: lease.propertyId,
    unit: lease.unit,
    stage: lease.stage,
    startDate: lease.startDate,
    endDate: lease.endDate,
    monthlyRent: lease.monthlyRent,
    termMonths: lease.termMonths,
    renewalStatus: lease.renewalStatus,
  };
}

// Deliberately public valuation DTO: propertyId is omitted since it's already implied by
// the /properties/{id}/valuations route path. The domain type only tracks one timestamp
// (recordedAt); valuationDate mirrors it under the public contract's required field name.
export type ValuationSummaryDtoV1 = {
  id: string;
  price: number;
  valuationDate: number;
  month: string;
  recordedAt: number;
};

export function toValuationSummaryDto(valuation: PropertyValuation): ValuationSummaryDtoV1 {
  return {
    id: valuation.id,
    price: valuation.price,
    valuationDate: valuation.recordedAt,
    month: valuation.month,
    recordedAt: valuation.recordedAt,
  };
}

// Deliberately public ownership DTO: propertyId is omitted since it's already implied by
// the /properties/{id}/ownership route path. verifiedAt, evidenceDocIds (raw document ids),
// and createdAt/updatedAt are internal-only and are never read by the web ownership page.
// Co-owners, ownership documents, and ownership history are separate entities and are
// intentionally left out of this minimal slice.
export type OwnershipDtoV1 = {
  id: string;
  holdingType: OwnershipRecord["holdingType"];
  loanType: string | undefined;
  loanAmount: number | undefined;
  loanTermYears: number | undefined;
  interestRate: number | undefined;
  originationDate: number | undefined;
  maturityDate: number | undefined;
  nextPaymentDue: number | undefined;
  lenderName: string | undefined;
  downPayment: number | undefined;
  closingCosts: number | undefined;
  distributionMethod: OwnershipRecord["distributionMethod"];
  verified: boolean | undefined;
};

export function toOwnershipDto(record: OwnershipRecord): OwnershipDtoV1 {
  return {
    id: record.id,
    holdingType: record.holdingType,
    loanType: record.loanType,
    loanAmount: record.loanAmount,
    loanTermYears: record.loanTermYears,
    interestRate: record.interestRate,
    originationDate: record.originationDate,
    maturityDate: record.maturityDate,
    nextPaymentDue: record.nextPaymentDue,
    lenderName: record.lenderName,
    downPayment: record.downPayment,
    closingCosts: record.closingCosts,
    distributionMethod: record.distributionMethod,
    verified: record.verified,
  };
}
