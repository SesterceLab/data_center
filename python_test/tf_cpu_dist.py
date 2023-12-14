#pip install tensorflow horovod
import tensorflow as tf
from tensorflow.keras import layers, models, optimizers, callbacks
from tensorflow.keras.datasets import mnist
from tensorflow.keras.utils import to_categorical
import time

# Horovod initialization
import horovod.tensorflow as hvd
hvd.init()

# Download and preprocess the MNIST dataset
(train_images, train_labels), (test_images, test_labels) = mnist.load_data()
train_images = train_images.reshape((60000, 28, 28, 1)).astype('float32') / 255
test_images = test_images.reshape((10000, 28, 28, 1)).astype('float32') / 255
train_labels = to_categorical(train_labels)
test_labels = to_categorical(test_labels)

# Split the dataset into batches for each worker
train_images = tf.split(train_images, hvd.size())[hvd.rank()]
train_labels = tf.split(train_labels, hvd.size())[hvd.rank()]

# Define the model architecture
model = models.Sequential()
model.add(layers.Conv2D(32, (3, 3), activation='relu', input_shape=(28, 28, 1)))
model.add(layers.MaxPooling2D((2, 2)))
model.add(layers.Conv2D(64, (3, 3), activation='relu'))
model.add(layers.MaxPooling2D((2, 2)))
model.add(layers.Conv2D(64, (3, 3), activation='relu'))
model.add(layers.Flatten())
model.add(layers.Dense(64, activation='relu'))
model.add(layers.Dense(10, activation='softmax'))

# Use Horovod's distributed optimizer
opt = optimizers.RMSprop(0.001 * hvd.size())

# Wrap the optimizer with Horovod
opt = hvd.DistributedOptimizer(opt)

# Compile the model
model.compile(optimizer=opt,
              loss='categorical_crossentropy',
              metrics=['accuracy'])

# Use TensorFlow callbacks for distributed training (learning rate scheduler, etc.)
callbacks_list = [
    callbacks.LearningRateScheduler(lambda epoch: 0.001 * hvd.size(), verbose=1)
]

# Record the start time
start_time = time.time()

# Training loop
model.fit(train_images, train_labels, epochs=5, batch_size=64, callbacks=callbacks_list)

# Record the end time
end_time = time.time()

# Calculate and print the elapsed time
elapsed_time = end_time - start_time
print(f'Training took {elapsed_time} seconds')

# Evaluate the model
test_loss, test_acc = model.evaluate(test_images, test_labels)
print(f'Test accuracy: {test_acc}')

# Save the model
model.save('distributed_mnist_model_cpu.keras')
