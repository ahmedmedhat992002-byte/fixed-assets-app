-- Create approvals table
CREATE TABLE public.approvals (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    asset_id UUID NOT NULL REFERENCES public.assets(id) ON DELETE CASCADE,
    requested_by UUID NOT NULL REFERENCES auth.users(id),
    action_type TEXT NOT NULL CHECK (action_type IN ('dispose', 'transfer')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
    approved_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    details JSONB
);

-- set up RLS for approvals
ALTER TABLE public.approvals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can insert an approval request"
    ON public.approvals FOR INSERT
    WITH CHECK (auth.uid() = requested_by);

CREATE POLICY "Users can view all approvals"
    ON public.approvals FOR SELECT
    USING (true);

CREATE POLICY "Admins can update approvals"
    ON public.approvals FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles 
            WHERE profiles.id = auth.uid() AND profiles.role = 'admin'
        )
    );

-- Create asset_timeline table
CREATE TABLE public.asset_timeline (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    asset_id UUID NOT NULL REFERENCES public.assets(id) ON DELETE CASCADE,
    action TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    details JSONB
);

-- set up RLS for asset_timeline
ALTER TABLE public.asset_timeline ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can insert timeline events"
    ON public.asset_timeline FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can view timeline events"
    ON public.asset_timeline FOR SELECT
    USING (true);
