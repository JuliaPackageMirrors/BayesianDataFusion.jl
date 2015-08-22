# BayesianDataFusion.jl package

This gives reference and examples for [BayesianDataFusion.jl](https://github.com/jaak-s/BayesianDataFusion.jl).

# Features
`BayesianDataFusion.jl` provides parallel and highly optimized implementation for

*  Bayesian Probabilistic Matrix Factorization (BPMF)
*  Bayesian Probabilistic Tensor Factorization (BPTF)
*  Macau - Bayesian Multi-relational Factorization with Side Information

These methods allow to predict **unobserved values** in the matrices (or tensors). Since they are all Bayesian methods we can also measure the **uncertainty** of the predictions. BPMF and BPTF are special cases of Macau. Macau adds

*  use of **entity side information** to improve factorization (e.g, user and/or movie features for factorizing movie ratings)
*  use of **relation side information** to improve factorization  (e.g., data about when user went to see particular movie)
*  factorization of **several** matrices (and tensors) for an entity simultaneously.

# Installation
Inside Julia:
```julia
Pkg.clone("https://github.com/jaak-s/BayesianDataFusion.jl.git")
```

# Examples
Next we give simple examples of using **Macau** for movie ratings prediction from MovieLens data, which is included in the BayesianDataFusion package.

## MovieLens
We will use `macau` function to factorization (incompletely observed) matrix of movie ratings with **side information** for both users and movies. To run the example first install Julia library for reading matlab files
```julia
Pkg.add("MAT")
```
Example code
```julia
using BayesianDataFusion
using MAT
## load and setup data
pkgdir = Pkg.dir("BayesianDataFusion")
data   = matread("$pkgdir/data/movielens_1m.mat")

## setup entities, assigning features through (optional) argument F
users  = Entity("users",  F=data["Fu"]);
movies = Entity("movies", F=data["Fv"]);

## setup the relation between users and movies, data from sparse matrix data["X"]
## first element in '[users, movies]' corresponds to rows and second to columns of data["X"]
ratings = Relation(data["X"], "ratings", [users, movies], class_cut = 2.5);

## assign 500,000 of the observed ratings randomly to the test set
assignToTest!(ratings, 500_000)

## precision of the ratings to 1.5 (i.e., variance of 1/1.5)
setPrecision!(ratings, 1.5)

## the model (with only one relation)
RD = RelationData(ratings)

## run Gibbs sampler of Macau with 10 latent dimensions, total of 400 burnin and 200 posterior samples
result = macau(RD, burnin=400, psamples=200, clamp=[1.0, 5.0], num_latent=10)
```
This model has only a single relation `ratings` between entities `users` and `movies`.
We use precision 1.5, which is known to be a good estimate of movie rating noise.
The optional parameter `clamp=[1.0, 5.0]` to `macau` thresholds the predictions to be between 1.0 and 5.0.
To build a model with larger latent dimension use, for example, `num_latent=30`.

Macau output shows the progress of the Gibbs sampler:
```
  1: Acc=0.836 ROC=0.500 RMSE=1.118 | use[U:  3.1 β:0.04 λ=21.] mov[U:  3.1 β:0.07 λ=10.] | rati[α=1.5] [4s]
  2: Acc=0.836 ROC=0.500 RMSE=1.118 | use[U:  4.4 β:0.03 λ=60.] mov[U:  4.4 β:0.04 λ=38.] | rati[α=1.5] [0s]
...
 80: Acc=0.864 ROC=0.829 RMSE=0.889 | use[U: 72.7 β:1.34 λ=4.5] mov[U:122.6 β:3.25 λ=3.1] | rati[α=1.5] [0s]
 81: Acc=0.864 ROC=0.829 RMSE=0.888 | use[U: 73.0 β:1.39 λ=5.3] mov[U:123.0 β:3.32 λ=3.2] | rati[α=1.5] [0s]
...
```
The Acc/ROC/RMSE are computed on the test ratings. Note the optional argument `class_cut = 2.5`, used for creating a `Relation`, defines the class boundary for computing accuracy (Acc) and AUC-ROC (ROC) values. 

## MovieLens w/o side-information
The above example used user and move features. You can easily factorize the ratings without them, which would correspond to classic **BPMF** method. Here is an example code
```julia
using BayesianDataFusion
using MAT
## load and setup data
pkgdir = Pkg.dir("BayesianDataFusion")
data   = matread("$pkgdir/data/movielens_1m.mat")

## setup entities, no features (F):
users  = Entity("users");
movies = Entity("movies");

## setup the relation between users and movies, data from sparse matrix data["X"]
## first element in '[users, movies]' corresponds to rows and second to columns of data["X"]
ratings = Relation(data["X"], "ratings", [users, movies], class_cut = 2.5);

## assign 500,000 of the observed ratings randomly to the test set
assignToTest!(ratings, 500_000)

## precision of the ratings to 1.5 (i.e., variance of 1/1.5)
setPrecision!(ratings, 1.5)

## the model (with only one relation)
RD = RelationData(ratings)

## run Gibbs sampler of Macau with 10 latent dimensions, total of 400 burnin and 200 posterior samples
result = macau(RD, burnin=400, psamples=200, clamp=[1.0, 5.0], num_latent=10)
```
In most applications the performance of pure BPMF is weaker compared to Macau. This is also true in the case of MovieLens dataset.