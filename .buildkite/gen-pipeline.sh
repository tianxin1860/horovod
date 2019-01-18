#!/bin/bash

# exit immediately on failure, or if an undefined variable is used
set -eu

# begin the pipeline.yml file
echo "steps:"

# list of all the tests
tests=(test-cpu-openmpi-py2_7-tf1_1_0-keras2_0_0-torch0_4_0-pyspark2_1_2 \
       test-cpu-openmpi-py3_5-tf1_1_0-keras2_0_0-torch0_4_0-pyspark2_1_2 \
       test-cpu-openmpi-py3_6-tf1_1_0-keras2_0_0-torch0_4_0-pyspark2_1_2 \
       test-cpu-openmpi-py2_7-tf1_6_0-keras2_1_2-torch0_4_1-pyspark2_3_2 \
       test-cpu-openmpi-py3_5-tf1_6_0-keras2_1_2-torch0_4_1-pyspark2_3_2 \
       test-cpu-openmpi-py3_6-tf1_6_0-keras2_1_2-torch0_4_1-pyspark2_3_2 \
       test-cpu-openmpi-py2_7-tf1_12_0-keras2_2_2-torch1_0_0-pyspark2_4_0 \
       test-cpu-openmpi-py3_5-tf1_12_0-keras2_2_2-torch1_0_0-pyspark2_4_0 \
       test-cpu-openmpi-py3_6-tf1_12_0-keras2_2_2-torch1_0_0-pyspark2_4_0 \
       test-cpu-openmpi-py2_7-tfhead-kerashead-torchhead-pyspark2_4_0 \
       test-cpu-openmpi-py3_6-tfhead-kerashead-torchhead-pyspark2_4_0 \
       test-cpu-mpich-py2_7-tf1_12_0-keras2_2_2-torch1_0_0-pyspark2_4_0)

# build every test container
for test in ${tests[@]}; do
  echo "- label: ':docker: Build ${test}'"
  echo "  plugins:"
  echo "  - docker-compose#v2.6.0:"
  echo "      build: ${test}"
  echo "      image-repository: gcr.io/uber-ma/user/asergeev/buildkite"
done

# wait for all builds to finish
echo "- wait"

# run all the tests
for test in ${tests[@]}; do
  echo "- label: ':pytest: Run PyTests (${test})'"
  echo "  command: bash -c \"cd /horovod/test && (echo test_*.py | xargs -n 1 \\\${MPIRUN} pytest -v)\""
  echo "  plugins:"
  echo "  - docker-compose#v2.6.0:"
  echo "      run: ${test}"

  echo "- label: ':hammer: Test TensorFlow MNIST (${test})'"
  echo "  command: bash -c \"\\\$(cat /mpirun_command) python /horovod/examples/tensorflow_mnist.py\""
  echo "  plugins:"
  echo "  - docker-compose#v2.6.0:"
  echo "      run: ${test}"

  if [[ ${test} != *"tf1_1_0"* && ${test} != *"tf1_6_0"* ]]; then
    echo "- label: ':hammer: Test TensorFlow Eager MNIST (${test})'"
    echo "  command: bash -c \"\\\$(cat /mpirun_command) python /horovod/examples/tensorflow_mnist_eager.py\""
    echo "  plugins:"
    echo "  - docker-compose#v2.6.0:"
    echo "      run: ${test}"
  fi

  echo "- label: ':hammer: Test Keras MNIST (${test})'"
  echo "  command: bash -c \"\\\$(cat /mpirun_command) python /horovod/examples/keras_mnist_advanced.py\""
  echo "  plugins:"
  echo "  - docker-compose#v2.6.0:"
  echo "      run: ${test}"

  echo "- label: ':hammer: Test PyTorch MNIST (${test})'"
  echo "  command: bash -c \"\\\$(cat /mpirun_command) python /horovod/examples/pytorch_mnist.py\""
  echo "  plugins:"
  echo "  - docker-compose#v2.6.0:"
  echo "      run: ${test}"
done
