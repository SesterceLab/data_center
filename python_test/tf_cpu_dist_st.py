import tensorflow as tf
from tensorflow.keras import layers, models, optimizers, callbacks
from tensorflow.keras.datasets import mnist
from tensorflow.keras.utils import to_categorical

# Define a function to create and compile the model
def create_model():
    model = models.Sequential()
    model.add(layers.Conv2D(32, (3, 3), activation='relu', input_shape=(28, 28, 1)))
    model.add(layers.MaxPooling2D((2, 2)))
    model.add(layers.Conv2D(64, (3, 3), activation='relu'))
    model.add(layers.MaxPooling2D((2, 2)))
    model.add(layers.Conv2D(64, (3, 3), activation='relu'))
    model.add(layers.Flatten())
    model.add(layers.Dense(64, activation='relu'))
    model.add(layers.Dense(10, activation='softmax'))

    opt = optimizers.RMSprop(0.001)
    model.compile(optimizer=opt,
                  loss='categorical_crossentropy',
                  metrics=['accuracy'])
    return model

# Load and preprocess the MNIST dataset
(train_images, train_labels), (test_images, test_labels) = mnist.load_data()
train_images = train_images.reshape((60000, 28, 28, 1)).astype('float32') / 255
test_images = test_images.reshape((10000, 28, 28, 1)).astype('float32') / 255
train_labels = to_categorical(train_labels)
test_labels = to_categorical(test_labels)

# Define Slurm cluster resolver
cluster_resolver = tf.distribute.cluster_resolver.SlurmClusterResolver()

# Create a ParameterServerStrategy
strategy = tf.distribute.experimental.ParameterServerStrategy(cluster_resolver)

# Open a Strategy scope
with strategy.scope():
    # Create and compile the model
    model = create_model()

# Train the model
train_dataset = tf.data.Dataset.from_tensor_slices((train_images, train_labels)).batch(64)
test_dataset = tf.data.Dataset.from_tensor_slices((test_images, test_labels)).batch(64)

# Use the strategy to distribute the training
with strategy.scope():
    model.fit(train_dataset, epochs=5)

# Evaluate the model
with strategy.scope():
    test_loss, test_acc = model.evaluate(test_dataset)
    print(f'Test accuracy: {test_acc}')

# Save the model
model.save('distributed_mnist_model.keras')
