"""Independent NumPy check of Stata restricted wild-cluster bootstrap fixture.
Run after tests/run.do; needs numpy, not Stata or scipy.
"""
from pathlib import Path
import argparse
import numpy as np


def check(directory):
    data = np.genfromtxt(directory / 'bootstrap_fixture.csv', delimiter=',', names=True)
    uniforms = np.genfromtxt(directory / 'bootstrap_uniforms.csv', delimiter=',', names=True)
    actual = np.genfromtxt(directory / 'bootstrap_results.csv', delimiter=',', names=True)
    x = np.column_stack([data['dose'], data['baseline'], data['control'], np.ones(len(data))])
    y = data['change']
    groups = data['group'].astype(int)
    unique = np.unique(groups)
    n, k = x.shape
    bread = np.linalg.inv(x.T @ x)

    def fit(response):
        coef = np.linalg.lstsq(x, response, rcond=None)[0]
        residual = response - x @ coef
        scores = np.array([x[groups == g].T @ residual[groups == g] for g in unique])
        cov = bread @ (scores.T @ scores) @ bread
        cov *= len(unique) / (len(unique) - 1) * (n - 1) / (n - k)
        return coef[1], np.sqrt(cov[1, 1])

    gamma, se = fit(y)
    np.testing.assert_allclose([gamma, se], [actual['gamma'], actual['se']], rtol=1e-11)
    restricted = x[:, [0, 2, 3]]
    ps = []
    for h, null in enumerate([0., .2], 1):
        adjusted = y - null * x[:, 1]
        restricted_fit = restricted @ np.linalg.lstsq(restricted, adjusted, rcond=None)[0]
        residual = adjusted - restricted_fit
        target = (gamma - null) / se
        count = 0
        for rep in range(1, 100):
            u = uniforms[(uniforms['h'] == h) & (uniforms['rep'] == rep)]['u']
            signs = np.where(u > .5, 1., -1.)[groups - 1]
            draw_gamma, draw_se = fit(restricted_fit + null * x[:, 1] + residual * signs)
            draw_t = (draw_gamma - null) / draw_se
            tolerance = 1e-12 * max(1., abs(target))
            count += (abs(draw_t) >= abs(target) - tolerance) if h == 1 else (draw_t >= target - tolerance)
        ps.append((1 + count) / 100)
    np.testing.assert_allclose(ps, [actual['p_equal_wild'], actual['p_cap_wild']], atol=1e-14)
    print(f'PASS: independent NumPy CR1 and null-imposed wild bootstrap; p-values={ps}')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--directory', type=Path, default=Path(__file__).resolve().parents[1] / 'tests')
    check(parser.parse_args().directory)
