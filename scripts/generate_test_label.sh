#!/usr/bin/env bash
# Generate a PostNL test shipping label via the sandbox API.
# Saves the PDF to scripts/test_label.pdf — print it and photograph for PostNL approval.
#
# Usage: bash scripts/generate_test_label.sh

set -euo pipefail

# Load .env
if [ -f .env ]; then
  # shellcheck disable=SC1091
  source .env
fi

API_KEY="${POSTNL_SANDBOX:?Missing POSTNL_SANDBOX in .env}"
BASE_URL="https://api-sandbox.postnl.nl"
CUSTOMER_CODE="RMUZ"
CUSTOMER_NUMBER="10959299"

echo "=== Step 1: Generate barcode ==="
BARCODE_RESP=$(curl -s \
  -H "apikey: $API_KEY" \
  -H "Accept: application/json" \
  "$BASE_URL/shipment/v1_1/barcode?CustomerCode=$CUSTOMER_CODE&CustomerNumber=$CUSTOMER_NUMBER&Type=3S&Serie=000000000-999999999")

BARCODE=$(echo "$BARCODE_RESP" | python3 -c "import sys,json; print(json.load(sys.stdin)['Barcode'])")
echo "Barcode: $BARCODE"

TIMESTAMP=$(date -u +"%d-%m-%Y %H:%M:%S")
MSG_ID=$(uuidgen | tr '[:upper:]' '[:lower:]')

echo "=== Step 2: Generate label (confirm=true, included) ==="
LABEL_RESP=$(curl -s -X POST \
  -H "apikey: $API_KEY" \
  -H "Accept: application/json" \
  -H "Content-Type: application/json" \
  "$BASE_URL/shipment/v2_2/label" \
  -d "{
    \"Customer\": {
      \"CustomerCode\": \"$CUSTOMER_CODE\",
      \"CustomerNumber\": \"$CUSTOMER_NUMBER\",
      \"CollectionLocation\": \"0000000000\",
      \"Address\": {
        \"AddressType\": \"02\",
        \"CompanyName\": \"DeelMarkt\",
        \"Street\": \"Keizersgracht\",
        \"HouseNr\": \"100\",
        \"Zipcode\": \"1015AA\",
        \"City\": \"Amsterdam\",
        \"Countrycode\": \"NL\"
      }
    },
    \"Message\": {
      \"MessageID\": \"$MSG_ID\",
      \"MessageTimeStamp\": \"$TIMESTAMP\",
      \"Printertype\": \"GraphicFile|PDF\"
    },
    \"Shipments\": [{
      \"Addresses\": [{
        \"AddressType\": \"01\",
        \"FirstName\": \"Test Ontvanger\",
        \"Street\": \"Waldorpstraat\",
        \"HouseNr\": \"3\",
        \"Zipcode\": \"2521CA\",
        \"City\": \"Den Haag\",
        \"Countrycode\": \"NL\"
      }],
      \"Barcode\": \"$BARCODE\",
      \"Contacts\": [{
        \"ContactType\": \"01\",
        \"Email\": \"info@deelmarkt.com\"
      }],
      \"Dimension\": { \"Weight\": \"1000\" },
      \"ProductCodeDelivery\": \"3085\",
      \"Reference\": \"test-label-for-postnl-approval\"
    }]
  }")

# Extract base64 PDF content
PDF_B64=$(echo "$LABEL_RESP" | python3 -c "
import sys, json
data = json.load(sys.stdin)
shipments = data.get('ResponseShipments', [])
if not shipments:
    print('ERROR: No shipments in response', file=sys.stderr)
    print(json.dumps(data, indent=2), file=sys.stderr)
    sys.exit(1)
labels = shipments[0].get('Labels', [])
if not labels:
    print('ERROR: No labels in response', file=sys.stderr)
    sys.exit(1)
print(labels[0]['Content'])
")

if [ -z "$PDF_B64" ]; then
  echo "ERROR: Failed to extract label PDF"
  echo "$LABEL_RESP" | python3 -m json.tool
  exit 1
fi

# Decode and save
OUTPUT="scripts/test_label.pdf"
echo "$PDF_B64" | base64 -d > "$OUTPUT"

echo ""
echo "=== Done ==="
echo "Label saved to: $OUTPUT"
echo "Barcode: $BARCODE"
echo ""
echo "Next steps:"
echo "  1. Open and print: open $OUTPUT"
echo "  2. Take a clear photo of the printed label"
echo "  3. Send the photo to PostNL (John van Persie)"
