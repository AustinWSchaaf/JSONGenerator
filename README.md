# JSONGenerator
Creates Decodable structs from a json input 

## Usage

````swift
let json = """
{
 "status": "OK",
 "count": 2,
 "results": [
  {
   "ticker": "AAPL",
   "exDate": "2020-05-08T00:00:00.000Z",
   "paymentDate": "2020-05-14T00:00:00.000Z",
   "recordDate": "2020-05-11T00:00:00.000Z",
   "amount": 0.82
  },
  {
   "ticker": "AAPL",
   "exDate": "2020-02-07T00:00:00.000Z",
   "paymentDate": "2020-02-13T00:00:00.000Z",
   "recordDate": "2020-02-10T00:00:00.000Z",
   "amount": 0.77
  }
 ]
}
"""
let s = JSONToStructGenerator(json: json)

````

## Output

````swift
public struct main: Decodable {
	public let status: String
	public let count: Int
	public let results: [results]
}

public struct results: Decodable {
	public let ticker: String
	public let exDate: String
	public let paymentDate: String
	public let recordDate: String
	public let amount: Double
}
````

## Warning
currently reliable but there may be some edge cases where it breaks
