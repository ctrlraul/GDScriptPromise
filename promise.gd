# https://github.com/ctrlraul/GDScriptPromise

# MIT License
# 
# Copyright (c) 2024 Ctrl Raul [mailctrlraul@gmail.com]
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

class_name Promise
extends Node

signal completed

enum State {
	Empty,
	Pending,
	Completed,
}

var state: State = State.Empty
var _result = null


func run(coroutine: Callable, arguments: Array = []) -> void:
	
	if state != State.Empty:
		push_error("Promise already used")
		return
	
	var wrapper = func() -> void:
		_result = await coroutine.callv(arguments)
		state = State.Completed
		completed.emit()
	
	wrapper.call_deferred()

func get_result():
	if state != State.Completed:
		await completed
	return _result

func set_result(data = null) -> void:
	if state == State.Completed:
		push_error("Promise already completed")
		return
	_result = data
	state = State.Completed
	completed.emit(_result)


static func timeout(seconds: float) -> Promise:
	return Promise.create_for_signal(delay(seconds))

static func create(coroutine: Callable, arguments: Array = []) -> Promise:
	var promise = Promise.new()
	promise.run(coroutine, arguments)
	return promise

static func create_for_signal(signal_: Signal) -> Promise:
	return Promise.create(func(): await signal_)

static func all(promises: Array) -> Promise:
	
	var results = []
	var ref_hack = { "count": 0 }
	var all_promise = Promise.new()
	
	results.resize(promises.size())
	
	all_promise.state = State.Pending
	
	var progress = func(index: int, result) -> void:
		results[index] = result
		results.size()
		ref_hack.count += 1
		if ref_hack.count == promises.size():
			all_promise.set_result(results)
	
	for i in promises.size():
		
		var promise: Promise = promises[i]
		
		match promise.state:
			
			State.Empty:
				promise.completed.connect(func(result): progress.call(i, result))
			
			State.Pending:
				promise.completed.connect(func(result): progress.call(i, result))
			
			State.Completed:
				progress.call(promise, i)
	
	return all_promise

static func request(url: String) -> Promise:
	
	var promise = Promise.new()
	var http = HTTPRequest.new()
	var response = {
		"error": null,
		"result": null,
		"code": null,
		"headers": null,
		"body": null,
	}
	
	promise.state = State.Pending
	
	Engine.get_main_loop().root.add_child(http)
	
	http.request_completed.connect(func(result, response_code, headers, body) -> void:
		response.result = result
		response.code = response_code
		response.headers = headers
		response.body = body
		http.queue_free()
		promise.set_result(response)
	)
	
	var error = http.request(url)
	if error != OK:
		response.error = "Error fetching '%s': %s" % [url, error_string(error)]
	
	return promise


static func delay(seconds: float) -> Signal:
	var tree: SceneTree = Engine.get_main_loop().root.get_tree()
	return tree.create_timer(seconds).timeout
