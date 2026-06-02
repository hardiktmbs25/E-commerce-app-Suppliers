{
  "indexes": [
    {
      "collectionGroup": "deliveries",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "scheduledDate",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "routeOrder",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "ASCENDING"
        }
      ],
      "density": "SPARSE_ALL"
    },
    {
      "collectionGroup": "invoices",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "status",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "dueDate",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "ASCENDING"
        }
      ],
      "density": "SPARSE_ALL"
    },
    {
      "collectionGroup": "ledger",
      "queryScope": "COLLECTION",
      "fields": [
        {
          "fieldPath": "customerId",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "createdAt",
          "order": "ASCENDING"
        },
        {
          "fieldPath": "__name__",
          "order": "ASCENDING"
        }
      ],
      "density": "SPARSE_ALL"
    }
  ],
  "fieldOverrides": []
}