# jsj
흠... 그정돈가?

### 민창아 나 열심히 할게

#### 문동원 할 수 있어
import pandas as pd
import numpy as np

np.random.seed(42)  # For reproducibility
data = {
    'Name': ['Alice', 'Bob', 'Charlie', 'David', 'Eva'],
    'Age': np.random.randint(20, 50, size=5),
    'Score': np.random.randint(50, 100, size=5)
}

df = pd.DataFrame(data)

df_sorted = df.sort_values(by='Score', ascending=False)  # Sort by 'Score'
summary = df.describe()  # Summary statistics

print("Original DataFrame:\n", df)
print("\nSorted by Score:\n", df_sorted)
print("\nSummary Statistics:\n", summary)

