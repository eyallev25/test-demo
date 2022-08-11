import os
from pathlib import Path
import time
from functools import wraps
import tempfile

# LOG_PATH = Path("/tmp/anun.*.log")
PACKAGES_SRC_PATH = Path("/app/test_packages")
SHORT_PIP_SRC_PATH = PACKAGES_SRC_PATH / "short"
LONG_PIP_SRC_PATH = PACKAGES_SRC_PATH / "long"

def benchmark(*, times: int):
    def wrapper(func):
        @wraps(func)
        def inner(*args, **kwargs):
            print("~" * 60)
            print(f"RUNNING {func.__name__} for {times} times")
            if hasattr(func, "__doc__") and func.__doc__:
                print(f"Description: {func.__doc__.strip()}")
            print("", flush=True)

            
            total = 0.0
            maximal = -1.0
            for i in range(times):
                print("")
                print(f"ITERATION {i+1}/{times}", flush=True)
                start_time = time.time()
                func(*args, **kwargs)
                duration = time.time() - start_time
                total += duration
                maximal = max(maximal, duration)

            print("")
            print(f"FINISHED RUNNING {func.__name__} for {times} times")
            print(f"TOTAL: {total}s, AVARAGE: {total / times}s, MAX: {maximal}s")
            print("", flush=True)
        return inner
    return wrapper


@benchmark(times=10)
def pip_short():
    """ Running pip install on small amount of packages """
    with tempfile.TemporaryDirectory() as d:
        os.system(f". /app/.venv/bin/activate && pip install --no-index -t {d} {SHORT_PIP_SRC_PATH}/*")

@benchmark(times=5)
def pip_long():
    """ Running pip install on large amount of packages """
    with tempfile.TemporaryDirectory() as d:
        os.system(f". /app/.venv/bin/activate && pip install --no-index -t {d} {LONG_PIP_SRC_PATH}/*")

@benchmark(times=50)
def dumb_commands():
    """ Running a bunch of dumb commands that don't do a lot """
    os.system("ls")
    os.system("echo $$")
    os.system("uname -a")
    os.system("ps aux")
    os.system("whoami")
    os.system("hostname")

@benchmark(times=20)
def aws():
    """ Running aws cli commands """
    os.system("aws --version")
    # os.system('aws sts get-caller-identity --query "Account"')
    # os.system("aws ssm get-parameters --with-decryption --names domain --query 'Parameters[*].Value' --output text")

def run_benchmarks():
    print(f"STARTING BENCHMARKS", flush=True)
    start_time = time.time()

    dumb_commands()
    pip_short()
    pip_long()
    aws()

    end_time = time.time()
    print(f"BENCHMARKS ENDED. TOTAL TIME: {end_time - start_time}s", flush=True)

if __name__ == "__main__":
    run_benchmarks()
