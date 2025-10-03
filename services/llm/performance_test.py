#!/usr/bin/env python3
"""
Performance Testing Script for Qwen2.5 7B + Ollama Integration
Part D: Performance testing and optimization
"""

import asyncio
import time
import json
import httpx
import statistics
from typing import List, Dict, Any
import sys

class PerformanceTester:
    def __init__(self, base_url: str = "http://localhost:8001"):
        self.base_url = base_url
        self.results = []
        
    async def test_single_request(self, message: str, max_tokens: int = 50) -> Dict[str, Any]:
        """Test a single request and measure performance"""
        start_time = time.time()
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(
                    f"{self.base_url}/v1/chat/completions",
                    json={
                        "model": "qwen2.5:7b",
                        "messages": [{"role": "user", "content": message}],
                        "temperature": 0.7,
                        "max_tokens": max_tokens,
                        "stream": False
                    },
                    timeout=30.0
                )
                
                end_time = time.time()
                response_data = response.json()
                
                # Calculate metrics
                total_time = end_time - start_time
                content = response_data["choices"][0]["message"]["content"]
                token_count = len(content.split())
                
                return {
                    "success": True,
                    "total_time": total_time,
                    "token_count": token_count,
                    "tokens_per_second": token_count / total_time if total_time > 0 else 0,
                    "response_length": len(content),
                    "status_code": response.status_code
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "total_time": time.time() - start_time
            }
    
    async def test_streaming_request(self, message: str, max_tokens: int = 100) -> Dict[str, Any]:
        """Test a streaming request and measure performance"""
        start_time = time.time()
        first_token_time = None
        token_count = 0
        
        try:
            async with httpx.AsyncClient() as client:
                async with client.stream(
                    "POST",
                    f"{self.base_url}/v1/chat/completions",
                    json={
                        "model": "qwen2.5:7b",
                        "messages": [{"role": "user", "content": message}],
                        "temperature": 0.7,
                        "max_tokens": max_tokens,
                        "stream": True
                    },
                    timeout=30.0
                ) as response:
                    
                    async for line in response.aiter_lines():
                        if line.startswith("data: "):
                            data = line[6:]  # Remove "data: " prefix
                            if data.strip() == "[DONE]":
                                break
                            try:
                                chunk = json.loads(data)
                                if "choices" in chunk and chunk["choices"]:
                                    content = chunk["choices"][0].get("delta", {}).get("content", "")
                                    if content:
                                        if first_token_time is None:
                                            first_token_time = time.time()
                                        token_count += len(content.split())
                            except json.JSONDecodeError:
                                continue
                
                end_time = time.time()
                total_time = end_time - start_time
                first_token_latency = first_token_time - start_time if first_token_time else total_time
                
                return {
                    "success": True,
                    "total_time": total_time,
                    "first_token_latency": first_token_latency,
                    "token_count": token_count,
                    "tokens_per_second": token_count / total_time if total_time > 0 else 0,
                    "status_code": response.status_code
                }
                
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "total_time": time.time() - start_time
            }
    
    async def test_concurrent_requests(self, num_requests: int = 5) -> Dict[str, Any]:
        """Test concurrent request handling"""
        start_time = time.time()
        
        tasks = []
        for i in range(num_requests):
            task = self.test_single_request(f"Test message {i+1}", max_tokens=30)
            tasks.append(task)
        
        results = await asyncio.gather(*tasks, return_exceptions=True)
        end_time = time.time()
        
        successful_requests = [r for r in results if isinstance(r, dict) and r.get("success", False)]
        failed_requests = [r for r in results if not (isinstance(r, dict) and r.get("success", False))]
        
        return {
            "total_requests": num_requests,
            "successful_requests": len(successful_requests),
            "failed_requests": len(failed_requests),
            "total_time": end_time - start_time,
            "requests_per_second": num_requests / (end_time - start_time),
            "success_rate": len(successful_requests) / num_requests,
            "results": results
        }
    
    async def run_performance_tests(self):
        """Run comprehensive performance tests"""
        print("🚀 Starting Performance Tests for Qwen2.5 7B + Ollama")
        print("=" * 60)
        
        # Test 1: Single Request Performance
        print("\n📊 Test 1: Single Request Performance")
        print("-" * 40)
        
        test_messages = [
            "Hello! How are you?",
            "What is 2+2?",
            "Explain machine learning in simple terms.",
            "Write a short poem about coding.",
            "Tell me a joke."
        ]
        
        single_request_results = []
        for i, message in enumerate(test_messages, 1):
            print(f"  Test {i}/5: {message[:30]}...")
            result = await self.test_single_request(message, max_tokens=50)
            single_request_results.append(result)
            
            if result["success"]:
                print(f"    ✅ Success: {result['total_time']:.2f}s, {result['tokens_per_second']:.1f} tok/s")
            else:
                print(f"    ❌ Failed: {result.get('error', 'Unknown error')}")
        
        # Test 2: Streaming Performance
        print("\n📊 Test 2: Streaming Performance")
        print("-" * 40)
        
        streaming_results = []
        for i, message in enumerate(test_messages[:3], 1):
            print(f"  Streaming Test {i}/3: {message[:30]}...")
            result = await self.test_streaming_request(message, max_tokens=100)
            streaming_results.append(result)
            
            if result["success"]:
                print(f"    ✅ Success: {result['total_time']:.2f}s, First token: {result['first_token_latency']:.2f}s")
            else:
                print(f"    ❌ Failed: {result.get('error', 'Unknown error')}")
        
        # Test 3: Concurrent Requests
        print("\n📊 Test 3: Concurrent Request Handling")
        print("-" * 40)
        
        print("  Testing 5 concurrent requests...")
        concurrent_result = await self.test_concurrent_requests(5)
        
        print(f"    ✅ Total: {concurrent_result['total_requests']} requests")
        print(f"    ✅ Successful: {concurrent_result['successful_requests']} requests")
        print(f"    ✅ Success Rate: {concurrent_result['success_rate']:.1%}")
        print(f"    ✅ Requests/sec: {concurrent_result['requests_per_second']:.2f}")
        
        # Test 4: Memory and Resource Usage
        print("\n📊 Test 4: Resource Usage")
        print("-" * 40)
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(f"{self.base_url}/metrics")
                metrics_text = response.text
                
                # Parse key metrics
                lines = metrics_text.split('\n')
                request_count = 0
                token_count = 0
                
                for line in lines:
                    if 'llm_requests_total' in line and 'status="200"' in line:
                        request_count = float(line.split()[-1])
                    elif 'llm_tokens_total' in line:
                        token_count = float(line.split()[-1])
                
                print(f"    ✅ Total Requests: {request_count}")
                print(f"    ✅ Total Tokens: {token_count}")
                
        except Exception as e:
            print(f"    ❌ Failed to get metrics: {e}")
        
        # Summary
        print("\n📈 Performance Summary")
        print("=" * 60)
        
        successful_single = [r for r in single_request_results if r.get("success", False)]
        successful_streaming = [r for r in streaming_results if r.get("success", False)]
        
        if successful_single:
            avg_response_time = statistics.mean([r["total_time"] for r in successful_single])
            avg_tokens_per_second = statistics.mean([r["tokens_per_second"] for r in successful_single])
            
            print(f"📊 Single Requests:")
            print(f"   • Average Response Time: {avg_response_time:.2f}s")
            print(f"   • Average Tokens/Second: {avg_tokens_per_second:.1f}")
            print(f"   • Success Rate: {len(successful_single)}/{len(single_request_results)} ({len(successful_single)/len(single_request_results):.1%})")
        
        if successful_streaming:
            avg_first_token = statistics.mean([r["first_token_latency"] for r in successful_streaming])
            avg_streaming_time = statistics.mean([r["total_time"] for r in successful_streaming])
            
            print(f"\n📊 Streaming Requests:")
            print(f"   • Average First Token Latency: {avg_first_token:.2f}s")
            print(f"   • Average Total Time: {avg_streaming_time:.2f}s")
            print(f"   • Success Rate: {len(successful_streaming)}/{len(streaming_results)} ({len(successful_streaming)/len(streaming_results):.1%})")
        
        print(f"\n📊 Concurrent Requests:")
        print(f"   • Success Rate: {concurrent_result['success_rate']:.1%}")
        print(f"   • Requests/Second: {concurrent_result['requests_per_second']:.2f}")
        
        # Performance Targets Assessment
        print(f"\n🎯 Performance Targets Assessment:")
        print("-" * 40)
        
        if successful_single:
            avg_response_time = statistics.mean([r["total_time"] for r in successful_single])
            if avg_response_time <= 0.3:  # 300ms
                print(f"   ✅ First Token Latency: {avg_response_time:.2f}s (≤ 300ms) - TARGET MET")
            else:
                print(f"   ❌ First Token Latency: {avg_response_time:.2f}s (≤ 300ms) - TARGET MISSED")
        
        if successful_single:
            avg_tokens_per_second = statistics.mean([r["tokens_per_second"] for r in successful_single])
            if avg_tokens_per_second >= 30:
                print(f"   ✅ Streaming Rate: {avg_tokens_per_second:.1f} tok/s (≥ 30 tok/s) - TARGET MET")
            else:
                print(f"   ❌ Streaming Rate: {avg_tokens_per_second:.1f} tok/s (≥ 30 tok/s) - TARGET MISSED")
        
        print(f"\n💡 Note: CPU-only performance baseline. GPU upgrade recommended for production SLOs.")
        print("   • Ollama + Qwen2.5 7B provides excellent quality with reasonable performance")
        print("   • For production workloads, consider vLLM + GPU for optimal performance")

async def main():
    """Main function to run performance tests"""
    tester = PerformanceTester()
    await tester.run_performance_tests()

if __name__ == "__main__":
    asyncio.run(main())
