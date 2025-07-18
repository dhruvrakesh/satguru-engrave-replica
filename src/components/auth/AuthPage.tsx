import React, { useState } from 'react';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Label } from '@/components/ui/label';
import { useAuth } from '@/contexts/AuthContext';
import { toast } from '@/hooks/use-toast';
import { Loader2 } from 'lucide-react';

export const AuthPage = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const { signIn, signUp } = useAuth();

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    try {
      console.log('🔐 Attempting sign in from AuthPage for:', email);
      const { error } = await signIn(email, password);
      
      if (error) {
        console.error('❌ Sign in failed in AuthPage:', error);
        
        let errorMessage = error.message;
        let errorTitle = "Sign In Failed";
        
        // Provide more helpful error messages
        if (error.message.includes('Invalid login credentials')) {
          errorTitle = "Invalid Credentials";
          errorMessage = "Please check your email and password. If you're a new user, try creating an account first.";
        } else if (error.message.includes('Email not confirmed')) {
          errorTitle = "Email Not Confirmed";
          errorMessage = "Please check your email and click the confirmation link.";
        }
        
        toast({
          title: errorTitle,
          description: errorMessage,
          variant: "destructive"
        });
      } else {
        console.log('✅ Sign in successful in AuthPage for:', email);
        toast({
          title: "Welcome back!",
          description: "You have been signed in successfully."
        });
      }
    } catch (err) {
      console.error('🚨 Unexpected error in AuthPage sign in:', err);
      toast({
        title: "Something went wrong",
        description: "An unexpected error occurred. Please try again.",
        variant: "destructive"
      });
    }
    
    setIsLoading(false);
  };

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    
    try {
      console.log('📝 Attempting sign up from AuthPage for:', email);
      const { error } = await signUp(email, password);
      
      if (error) {
        console.error('❌ Sign up failed in AuthPage:', error);
        
        let errorMessage = error.message;
        let errorTitle = "Sign Up Failed";
        
        // Provide more helpful error messages
        if (error.message.includes('already registered')) {
          errorTitle = "Account Already Exists";
          errorMessage = "This email is already registered. Try signing in instead.";
        }
        
        toast({
          title: errorTitle,
          description: errorMessage,
          variant: "destructive"
        });
      } else {
        console.log('✅ Sign up successful in AuthPage for:', email);
        toast({
          title: "Account Created",
          description: "Please check your email to verify your account."
        });
      }
    } catch (err) {
      console.error('🚨 Unexpected error in AuthPage sign up:', err);
      toast({
        title: "Something went wrong",
        description: "An unexpected error occurred. Please try again.",
        variant: "destructive"
      });
    }
    
    setIsLoading(false);
  };

  // Determine placeholder based on email domain
  const getPlaceholderEmail = () => {
    if (email.includes('@satguruengravures.com')) return 'info@satguruengravures.com';
    if (email.includes('@dkenterprises.co.in')) return 'info@dkenterprises.co.in';
    return 'admin@yourorganization.com';
  };
  
  const organizationName = 'Multi-Tenant ERP System';

  return (
    <div className="min-h-screen flex items-center justify-center bg-background p-4">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <CardTitle className="text-2xl font-bold">{organizationName}</CardTitle>
          <CardDescription>
            Sign in to access your organization's inventory management system
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs defaultValue="signin" className="w-full">
            <TabsList className="grid w-full grid-cols-2">
              <TabsTrigger value="signin">Sign In</TabsTrigger>
              <TabsTrigger value="signup">Sign Up</TabsTrigger>
            </TabsList>
            
            <TabsContent value="signin">
              <form onSubmit={handleSignIn} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="signin-email">Email</Label>
                  <Input
                    id="signin-email"
                    type="email"
                    placeholder={getPlaceholderEmail()}
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="signin-password">Password</Label>
                  <Input
                    id="signin-password"
                    type="password"
                    placeholder="Enter your password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                </div>
                <Button 
                  type="submit" 
                  className="w-full" 
                  disabled={isLoading}
                >
                  {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                  Sign In
                </Button>
              </form>
            </TabsContent>
            
            <TabsContent value="signup">
              <form onSubmit={handleSignUp} className="space-y-4">
                <div className="space-y-2">
                  <Label htmlFor="signup-email">Email</Label>
                  <Input
                    id="signup-email"
                    type="email"
                    placeholder="your.email@domain.com"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="signup-password">Password</Label>
                  <Input
                    id="signup-password"
                    type="password"
                    placeholder="Create a strong password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                    minLength={6}
                  />
                </div>
                <Button 
                  type="submit" 
                  className="w-full" 
                  disabled={isLoading}
                >
                  {isLoading && <Loader2 className="mr-2 h-4 w-4 animate-spin" />}
                  Create Account
                </Button>
              </form>
            </TabsContent>
          </Tabs>
          
          <div className="mt-6 p-4 bg-muted rounded-lg">
            <div className="text-center text-sm text-muted-foreground space-y-2">
              <div className="font-semibold">Admin Accounts:</div>
              <div className="space-y-1">
                <div>🏢 DK Enterprises: <code className="bg-background px-1 rounded">info@dkenterprises.co.in</code></div>
                <div>🎨 Satguru Engravures: <code className="bg-background px-1 rounded">info@satguruengravures.com</code></div>
              </div>
              <div className="text-xs text-muted-foreground/70 mt-2">
                💡 If you're having trouble signing in, try creating an account first with the same email
              </div>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};