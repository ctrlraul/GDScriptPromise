# GDScript Promise (awaiting utils)

An utility mainly to implement some C#'s `Task`-like functionality in GDScript.

## Why

GDScript currently implements no way to interact with pending tasks, such as calling a coroutine and adding it to an array of on-going coroutines, checking if whether it's finished already, or obtaining it's return value past the finish time. This script enable all of these use cases.

## Examples

1. Load an image from web using `Promise.request` for an awaitable http request
```gdscript
var response = await Promise.request("https://picsum.photos/100").get_result()

if response.error == null:
    var image = Image.new()
    image.load_jpg_from_buffer(response.body)
    sprite2D.texture = ImageTexture.create_from_image(image)
```

2. Make an arbitrary set of requests in parallel and wait until all of them are done to get the responses
```gdscript
var promises = []

for i in count:
    var promise = Promise.request("https://picsum.photos/100")
    promises.append(promise)

var responses = await Promise.all(promises).get_result()
```

3. Using an empty promise to arbitrarily wait for a value provided from anywhere else (Silly example)
```gdscript
var input_promise = null

func wait_for_input() -> void:
    input_promise = Promise.new()
    var value = await input_promise.get_result()
    print("Input value: ", input)


func on_input(value) -> void:
    input_promise.set_result(value)
```

Misc
```gdscript
# Wrap coroutines
var promise = Promise.create(_something_async)

# Passing arguments
var promise = Promise.create(_something_with_args_async, ["first_argument", "second_argument", 3, true])

# Wrap signals
var promise = Promise.create_for_signal(node.tree_exited)

# Promise that completes after 10 seconds
var promise = Promise.timeout(10)

# "Sleep" for 10 seconds
await Promise.delay(10)
```

# This might be updated in future