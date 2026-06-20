export interface PaginationMetadata {
  page: number;
  limit: number;
  totalItems: number;
  totalPages: number;
}

/**
 * Calculates pagination metadata for response matching API response format.
 */
export function getPaginationMetadata(
  page: number,
  limit: number,
  totalItems: number
): PaginationMetadata {
  const totalPages = Math.ceil(totalItems / limit) || 1;
  return {
    page,
    limit,
    totalItems,
    totalPages,
  };
}
